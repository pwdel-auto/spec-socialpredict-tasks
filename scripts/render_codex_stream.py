#!/usr/bin/env python3
"""Render raw Codex streams into concise terminal output while preserving logs."""

from __future__ import annotations

import argparse
import json
import sys
import textwrap
import time
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stream", choices=("events", "stderr"), required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--activity-file", required=True)
    parser.add_argument("--task-ref", default="unknown")
    parser.add_argument("--segment", default="?")
    return parser.parse_args()


def touch_activity(path: Path) -> None:
    path.write_text(f"{int(time.time())}\n", encoding="utf-8")


def shorten(text: str, limit: int = 120) -> str:
    text = " ".join((text or "").split())
    if len(text) <= limit:
        return text
    return text[: limit - 3] + "..."


def emit(prefix: str, text: str, *, stream) -> None:
    wrapped = textwrap.wrap(text, width=110) or [""]
    for idx, chunk in enumerate(wrapped):
        label = prefix if idx == 0 else " " * len(prefix)
        print(f"{label}{chunk}", file=stream, flush=True)


def render_command_status(item: dict, *, stream, task_ref: str, segment: str) -> None:
    command = shorten(item.get("command") or "")
    exit_code = item.get("exit_code")
    status = item.get("status") or "completed"
    prefix = f"[codex-runner][task={task_ref}][segment={segment}] "

    if status == "in_progress":
        emit(prefix, f"cmd start: {command}", stream=stream)
        return

    if exit_code == 0 and status == "completed":
        emit(prefix, f"cmd ok: {command}", stream=stream)
        return

    emit(prefix, f"cmd failed ({exit_code}): {command}", stream=stream)
    output = (item.get("aggregated_output") or "").strip()
    if output:
        preview = shorten(output.splitlines()[-1], limit=140)
        emit(prefix, f"last output: {preview}", stream=stream)


def render_collab_status(item: dict, *, stream, task_ref: str, segment: str) -> None:
    tool = item.get("tool") or "agent"
    status = item.get("status") or "completed"
    receivers = item.get("receiver_thread_ids") or []
    prefix = f"[codex-runner][task={task_ref}][segment={segment}] "

    if status == "in_progress":
        emit(prefix, f"agent action started: {tool}", stream=stream)
        return

    extra = ""
    if tool == "spawn_agent" and receivers:
        extra = f" ({len(receivers)} agent{'s' if len(receivers) != 1 else ''})"
    emit(prefix, f"agent action completed: {tool}{extra}", stream=stream)


def render_agent_message(item: dict, *, stream, task_ref: str, segment: str) -> None:
    text = (item.get("text") or "").strip()
    if not text:
        return
    prefix = f"[codex-runner][task={task_ref}][segment={segment}] "
    emit(prefix, text, stream=stream)


def render_event_line(raw: str, *, stream, task_ref: str, segment: str) -> None:
    prefix = f"[codex-runner][task={task_ref}][segment={segment}] "
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        emit(prefix, shorten(raw, limit=140), stream=stream)
        return

    event_type = payload.get("type")
    if event_type == "thread.started":
        emit(prefix, f"session started: {payload.get('thread_id') or payload.get('id') or 'unknown'}", stream=stream)
        return
    if event_type == "turn.started":
        emit(prefix, "turn started", stream=stream)
        return
    if event_type == "error":
        emit(prefix, f"error: {payload.get('message') or 'unknown error'}", stream=stream)
        return

    item = payload.get("item")
    if not isinstance(item, dict):
        return

    item_type = item.get("type")
    if item_type == "agent_message" and event_type == "item.completed":
        render_agent_message(item, stream=stream, task_ref=task_ref, segment=segment)
        return
    if item_type == "command_execution":
        render_command_status(item, stream=stream, task_ref=task_ref, segment=segment)
        return
    if item_type == "collab_tool_call":
        render_collab_status(item, stream=stream, task_ref=task_ref, segment=segment)
        return


def main() -> int:
    args = parse_args()
    output_path = Path(args.output)
    activity_path = Path(args.activity_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    activity_path.parent.mkdir(parents=True, exist_ok=True)

    sink = sys.stderr if args.stream == "stderr" else sys.stdout
    touch_activity(activity_path)

    with output_path.open("w", encoding="utf-8") as out:
        for raw in sys.stdin:
            out.write(raw)
            out.flush()
            touch_activity(activity_path)
            if args.stream == "events":
                render_event_line(raw.strip(), stream=sink, task_ref=args.task_ref, segment=args.segment)
            else:
                line = raw.rstrip("\n")
                if line:
                    prefix = f"[codex-runner][task={args.task_ref}][segment={args.segment}][stderr] "
                    emit(prefix, shorten(line, limit=140), stream=sink)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
