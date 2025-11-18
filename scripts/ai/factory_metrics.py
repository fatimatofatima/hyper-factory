#!/usr/bin/env python3
import os
import json
import uuid
from datetime import datetime
from collections import Counter
from typing import Dict, Any, Optional

_THIS_DIR = os.path.dirname(__file__)
ROOT_DIR = os.path.abspath(os.path.join(_THIS_DIR, "..", ".."))
LOGS_DIR = os.path.join(ROOT_DIR, "logs")
METRICS_PATH = os.path.join(LOGS_DIR, "factory_metrics.jsonl")


def log_metric(
    agent: str,
    event_type: str,
    user_id: Optional[str] = None,
    meta: Optional[Dict[str, Any]] = None,
) -> None:
    os.makedirs(LOGS_DIR, exist_ok=True)
    rec = {
        "id": str(uuid.uuid4()),
        "ts": datetime.utcnow().isoformat() + "Z",
        "agent": agent,
        "event_type": event_type,
        "user_id": user_id,
        "meta": meta or {},
    }
    with open(METRICS_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")


def summarize_metrics() -> None:
    if not os.path.exists(METRICS_PATH):
        print("no metrics yet")
        return
    agents = Counter()
    events = Counter()
    with open(METRICS_PATH, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            agents[obj.get("agent", "unknown")] += 1
            events[obj.get("event_type", "unknown")] += 1

    print("===== Factory Metrics Summary =====")
    total = sum(events.values())
    print(f"Total events: {total}")
    print("\nBy agent:")
    for k, v in agents.most_common():
        print(f" - {k}: {v}")
    print("\nBy event_type:")
    for k, v in events.most_common():
        print(f" - {k}: {v}")


def main() -> None:
    import argparse

    p = argparse.ArgumentParser()
    p.add_argument("command", choices=["summary"])
    a = p.parse_args()
    if a.command == "summary":
        summarize_metrics()


if __name__ == "__main__":
    main()
