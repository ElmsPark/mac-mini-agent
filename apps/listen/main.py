import os
import shutil
import signal
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

import yaml
from fastapi import Depends, FastAPI, HTTPException, Security
from fastapi.responses import PlainTextResponse
from fastapi.security import APIKeyHeader
from pydantic import BaseModel

app = FastAPI()

JOBS_DIR = Path(__file__).parent / "jobs"
JOBS_DIR.mkdir(exist_ok=True)
ARCHIVED_DIR = JOBS_DIR / "archived"

# API key authentication -- key loaded from LISTEN_API_KEY env var.
# If the env var is not set, auth is disabled (local dev convenience).
_api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)
LISTEN_API_KEY = os.environ.get("LISTEN_API_KEY", "")


def _verify_api_key(key: str = Security(_api_key_header)):
    """Reject requests with a missing or wrong API key (if auth is enabled)."""
    if not LISTEN_API_KEY:
        return  # Auth disabled when env var is empty
    if key != LISTEN_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")


class JobRequest(BaseModel):
    prompt: str
    mode: str = ""  # "direct" (default), "fast" (tmux), "sdk" (Agent SDK)
    name: str = ""  # optional human-friendly name (e.g. "dev3")
    model: str = ""  # "sonnet", "opus", or "" for default. Sonnet for mechanical tasks, Opus for creative/complex.


# Worker modes:
#   "direct" -- subprocess.run() with claude -p. Works under launchd. Uses Max subscription.
#   "fast"   -- tmux session with claude -p. Only works in a terminal (not launchd).
#   "sdk"    -- Agent SDK query(). Requires ANTHROPIC_API_KEY (separate billing).
DEFAULT_WORKER_MODE = os.environ.get("WORKER_MODE", "direct")


@app.post("/job")
def create_job(req: JobRequest, _auth=Depends(_verify_api_key)):
    job_id = uuid4().hex[:8]
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    mode = req.mode or DEFAULT_WORKER_MODE
    if mode not in ("sdk", "fast", "direct"):
        mode = "direct"

    # If a name is given, use it as the job ID (overwrite previous job with same name)
    if req.name:
        job_id = req.name

    model = req.model if req.model in ("sonnet", "opus", "haiku") else ""

    job_data = {
        "id": job_id,
        "status": "running",
        "prompt": req.prompt,
        "created_at": now,
        "pid": 0,
        "updates": [],
        "summary": "",
        "mode": mode,
        "model": model,
    }

    # Write YAML before spawning worker (worker reads it on startup)
    job_file = JOBS_DIR / f"{job_id}.yaml"
    with open(job_file, "w") as f:
        yaml.dump(job_data, f, default_flow_style=False, sort_keys=False)

    # Pick worker based on mode
    if mode == "fast":
        worker_path = Path(__file__).parent / "worker_tmux.py"
    elif mode == "sdk":
        worker_path = Path(__file__).parent / "worker.py"
    else:  # "direct" (default) -- works under launchd, uses Max subscription
        worker_path = Path(__file__).parent / "worker_direct.py"

    repo_root = Path(__file__).parent.parent.parent
    worker_log = JOBS_DIR / f"{job_id}.log"

    # Debug: log the exact command and environment
    with open(worker_log, "w") as dbg:
        dbg.write(f"python: {sys.executable}\n")
        dbg.write(f"worker: {worker_path}\n")
        dbg.write(f"exists: {worker_path.exists()}\n")
        dbg.write(f"cwd: {repo_root}\n")
        dbg.write(f"PATH: {os.environ.get('PATH', 'NOT SET')}\n")
        dbg.write(f"ANTHROPIC_API_KEY: {'set' if os.environ.get('ANTHROPIC_API_KEY') else 'NOT SET'}\n")
        dbg.flush()

    log_fh = open(worker_log, "a")
    worker_args = [sys.executable, str(worker_path), job_id, req.prompt]
    if model:
        worker_args.extend(["--model", model])

    proc = subprocess.Popen(
        worker_args,
        cwd=str(repo_root),
        stdout=log_fh,
        stderr=log_fh,
        start_new_session=True,
    )

    # Update PID after spawn
    job_data["pid"] = proc.pid
    with open(job_file, "w") as f:
        yaml.dump(job_data, f, default_flow_style=False, sort_keys=False)

    return {"job_id": job_id, "status": "running", "mode": mode}


@app.get("/job/{job_id}", response_class=PlainTextResponse)
def get_job(job_id: str, _auth=Depends(_verify_api_key)):
    job_file = JOBS_DIR / f"{job_id}.yaml"
    if not job_file.exists():
        raise HTTPException(status_code=404, detail="Job not found")
    return job_file.read_text()


@app.get("/jobs", response_class=PlainTextResponse)
def list_jobs(archived: bool = False, _auth=Depends(_verify_api_key)):
    search_dir = ARCHIVED_DIR if archived else JOBS_DIR
    jobs = []
    for f in sorted(search_dir.glob("*.yaml")):
        with open(f) as fh:
            data = yaml.safe_load(fh)
        jobs.append({
            "id": data.get("id"),
            "status": data.get("status"),
            "prompt": data.get("prompt"),
            "created_at": data.get("created_at"),
        })
    result = yaml.dump({"jobs": jobs}, default_flow_style=False, sort_keys=False)
    return result


@app.post("/jobs/clear")
def clear_jobs(_auth=Depends(_verify_api_key)):
    ARCHIVED_DIR.mkdir(exist_ok=True)
    count = 0
    for f in JOBS_DIR.glob("*.yaml"):
        shutil.move(str(f), str(ARCHIVED_DIR / f.name))
        count += 1
    return {"archived": count}


@app.delete("/job/{job_id}")
def stop_job(job_id: str, _auth=Depends(_verify_api_key)):
    job_file = JOBS_DIR / f"{job_id}.yaml"
    if not job_file.exists():
        raise HTTPException(status_code=404, detail="Job not found")

    with open(job_file) as f:
        data = yaml.safe_load(f)

    pid = data.get("pid")
    if pid:
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass

    data["status"] = "stopped"
    with open(job_file, "w") as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False)

    return {"job_id": job_id, "status": "stopped"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=7600)
