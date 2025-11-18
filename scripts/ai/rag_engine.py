#!/usr/bin/env python3
import os
import argparse
import json
import re
from typing import List, Dict, Any, Tuple

_THIS_DIR = os.path.dirname(__file__)
ROOT_DIR = os.path.abspath(os.path.join(_THIS_DIR, "..", ".."))
DEFAULT_KNOWLEDGE_DIR = os.path.join(ROOT_DIR, "ai", "datasets", "knowledge_chunks")


def _tokenize(text: str) -> List[str]:
    return [t for t in re.split(r"\W+", text.lower()) if t]


def _score_overlap(q: List[str], d: List[str]) -> float:
    if not q or not d:
        return 0.0
    qset, dset = set(q), set(d)
    inter = qset & dset
    return len(inter) / float(len(qset))


def search_knowledge(
    query: str,
    top_k: int = 5,
    knowledge_dir: str = DEFAULT_KNOWLEDGE_DIR,
) -> List[Dict[str, Any]]:
    os.makedirs(knowledge_dir, exist_ok=True)
    q_tokens = _tokenize(query)
    results: List[Tuple[float, str, str]] = []
    for root, _, files in os.walk(knowledge_dir):
        for fname in files:
            if not fname.lower().endswith(".txt"):
                continue
            path = os.path.join(root, fname)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    content = f.read()
            except Exception:
                continue
            score = _score_overlap(q_tokens, _tokenize(content))
            if score > 0:
                results.append((score, path, content[:1200]))
    results.sort(key=lambda x: x[0], reverse=True)
    return [
        {"score": float(s), "path": p, "preview": c}
        for s, p, c in results[:top_k]
    ]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--query", required=True)
    parser.add_argument("--top-k", type=int, default=5)
    parser.add_argument("--knowledge-dir", default=DEFAULT_KNOWLEDGE_DIR)
    args = parser.parse_args()
    res = search_knowledge(args.query, args.top_k, args.knowledge_dir)
    print(json.dumps({"results": res}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
