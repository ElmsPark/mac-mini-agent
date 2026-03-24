"""Job worker -- runs a Claude Code agent via the Agent SDK.

Uses claude_agent_sdk.query() instead of tmux/sentinel. The agent gets
built-in tools (Bash, Read, Edit, etc.), loads skills from .claude/skills/,
and streams structured messages back. No tmux, no sentinel, no polling.
"""

import asyncio
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import yaml

# Maximum job duration: 30 minutes. Prevents infinite API credit burn.
MAX_JOB_SECONDS = 30 * 60


def _update_job(job_file: Path, **fields):
    """Update fields in the job YAML file."""
    with open(job_file) as f:
        data = yaml.safe_load(f)
    data.update(fields)
    with open(job_file, "w") as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False)


async def run_agent(job_id: str, prompt: str, job_file: Path, repo_root: Path):
    """Run the agent via the SDK and stream results into the job YAML."""
    from claude_agent_sdk import query, ClaudeAgentOptions

    # Build the system prompt with job ID
    sys_prompt_file = (
        repo_root / ".claude" / "agents" / "listen-drive-and-steer-system-prompt.md"
    )
    sys_prompt = sys_prompt_file.read_text().replace("{{JOB_ID}}", job_id)

    # Build the user prompt (same content as the slash command template)
    user_prompt_file = (
        repo_root / ".claude" / "commands" / "listen-drive-and-steer-user-prompt.md"
    )
    user_prompt_template = user_prompt_file.read_text()
    # Strip the YAML frontmatter
    if user_prompt_template.startswith("---"):
        _, _, user_prompt_template = user_prompt_template.split("---", 2)
    user_prompt = user_prompt_template.replace("$ARGUMENTS", prompt).strip()

    # Combine system and user prompts
    full_system = sys_prompt + "\n\n" + user_prompt

    result_text = ""
    exit_code = 0

    try:
        async for message in query(
            prompt=prompt,
            options=ClaudeAgentOptions(
                system_prompt=full_system,
                allowed_tools=[
                    "Bash", "Read", "Write", "Edit",
                    "Glob", "Grep", "Agent",
                ],
                cwd=str(repo_root),
                max_turns=50,
            ),
        ):
            # Extract the final result text
            if hasattr(message, "result") and message.result:
                result_text = str(message.result)

    except Exception as e:
        import traceback
        result_text = f"Agent error: {e}\n{traceback.format_exc()}"
        print(result_text, file=sys.stderr)
        exit_code = 1

    return exit_code, result_text


def main():
    if len(sys.argv) < 3:
        print("Usage: worker.py <job_id> <prompt>")
        sys.exit(1)

    job_id = sys.argv[1]
    prompt = sys.argv[2]

    jobs_dir = Path(__file__).parent / "jobs"
    job_file = jobs_dir / f"{job_id}.yaml"

    if not job_file.exists():
        print(f"Job file not found: {job_file}")
        sys.exit(1)

    repo_root = Path(__file__).parent.parent.parent

    # Change to repo root so the SDK finds .claude/skills/
    os.chdir(repo_root)

    start_time = time.time()

    # Strip CLAUDECODE from env so nested claude doesn't conflict
    env_clean = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}
    os.environ.clear()
    os.environ.update(env_clean)

    try:
        # Run the agent with a timeout
        exit_code, result_text = asyncio.run(
            asyncio.wait_for(
                run_agent(job_id, prompt, job_file, repo_root),
                timeout=MAX_JOB_SECONDS,
            )
        )
    except asyncio.TimeoutError:
        exit_code = -1
        result_text = f"Job exceeded {MAX_JOB_SECONDS}s timeout."
        print(f"TIMEOUT: {result_text}", file=sys.stderr)
    except Exception as e:
        exit_code = 1
        result_text = f"Worker error: {e}"
        print(f"Worker error: {e}", file=sys.stderr)

    duration = round(time.time() - start_time)
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Determine status
    if exit_code == -1:
        status = "timeout"
    elif exit_code == 0:
        status = "completed"
    else:
        status = "failed"

    # Write final state -- the agent may have already updated the YAML
    # with progress/summary via yq, so re-read before writing
    _update_job(
        job_file,
        status=status,
        exit_code=exit_code,
        duration_seconds=duration,
        completed_at=now,
    )

    # If the agent wrote a summary via yq, it's already in the YAML.
    # If it didn't (error/timeout), write the result text as summary.
    with open(job_file) as f:
        data = yaml.safe_load(f)
    if not data.get("summary"):
        _update_job(job_file, summary=result_text[:500] if result_text else "")


if __name__ == "__main__":
    main()
