"""Job worker -- runs Claude Code CLI directly as a subprocess.

No tmux, no SDK. Just subprocess.run() with claude -p.
Works under launchd because it doesn't need a terminal session.
Uses the Max subscription (no API key needed) when claude is logged in.
"""

import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import yaml

MAX_JOB_SECONDS = 30 * 60


def _update_job(job_file: Path, **fields):
    """Update fields in the job YAML file."""
    with open(job_file) as f:
        data = yaml.safe_load(f)
    data.update(fields)
    with open(job_file, "w") as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False)


def main():
    if len(sys.argv) < 3:
        print("Usage: worker_direct.py <job_id> <prompt> [--model sonnet|opus|haiku]")
        sys.exit(1)

    job_id = sys.argv[1]
    prompt = sys.argv[2]

    # Parse optional --model flag
    model = ""
    if "--model" in sys.argv:
        idx = sys.argv.index("--model")
        if idx + 1 < len(sys.argv):
            model = sys.argv[idx + 1]

    jobs_dir = Path(__file__).parent / "jobs"
    job_file = jobs_dir / f"{job_id}.yaml"

    if not job_file.exists():
        print(f"Job file not found: {job_file}")
        sys.exit(1)

    repo_root = Path(__file__).parent.parent.parent

    # Load the system prompt
    sys_prompt_file = (
        repo_root / ".claude" / "agents" / "listen-drive-and-steer-system-prompt.md"
    )
    sys_prompt = sys_prompt_file.read_text().replace("{{JOB_ID}}", job_id)

    # Load the user prompt template
    user_prompt_file = (
        repo_root / ".claude" / "commands" / "listen-drive-and-steer-user-prompt.md"
    )
    user_prompt_template = user_prompt_file.read_text()
    if user_prompt_template.startswith("---"):
        _, _, user_prompt_template = user_prompt_template.split("---", 2)
    user_prompt = user_prompt_template.replace("$ARGUMENTS", prompt).strip()

    # Strip CLAUDECODE from env
    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

    start_time = time.time()

    import subprocess

    try:
        cmd = [
            "claude", "-p",
            "--max-turns", "50",
            "--output-format", "text",
            "--dangerously-skip-permissions",
            "--append-system-prompt", sys_prompt,
        ]
        if model:
            cmd.extend(["--model", model])

        result = subprocess.run(
            cmd,
            input=user_prompt,
            capture_output=True,
            text=True,
            timeout=MAX_JOB_SECONDS,
            cwd=str(repo_root),
            env=env,
        )

        exit_code = result.returncode
        output = result.stdout.strip()
        stderr = result.stderr.strip()

        if exit_code == 0:
            summary = output[:500] if output else "Completed with no output."
        else:
            summary = f"Failed (exit {exit_code}): {stderr[:300] or output[:300]}"

    except subprocess.TimeoutExpired:
        exit_code = -1
        summary = f"Job exceeded {MAX_JOB_SECONDS}s timeout."
    except Exception as e:
        exit_code = 1
        summary = f"Worker error: {e}"

    duration = round(time.time() - start_time)
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    if exit_code == -1:
        status = "timeout"
    elif exit_code == 0:
        status = "completed"
    else:
        status = "failed"

    _update_job(
        job_file,
        status=status,
        exit_code=exit_code,
        duration_seconds=duration,
        completed_at=now,
        summary=summary,
    )


if __name__ == "__main__":
    main()
