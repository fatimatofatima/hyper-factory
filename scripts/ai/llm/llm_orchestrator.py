#!/usr/bin/env python3
import os
import sys
from typing import Dict, Any, List

import yaml

_THIS_DIR = os.path.dirname(__file__)
ROOT_DIR = os.path.abspath(os.path.join(_THIS_DIR, "..", ".."))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

from scripts.ai.rag_engine import search_knowledge
from scripts.ai.factory_metrics import log_metric

CONFIG_PATH = os.path.join(ROOT_DIR, "config", "orchestrator.yaml")


class LLMOrchestrator:
    def __init__(self) -> None:
        if not os.path.exists(CONFIG_PATH):
            raise FileNotFoundError(CONFIG_PATH)
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            cfg = yaml.safe_load(f) or {}
        self.config = cfg
        self.routing = cfg.get("routing", {})
        self.rag_cfg = cfg.get("rag", {})

    def _select_agent(self, message: str) -> str:
        msg = message.lower()
        if any(k.lower() in msg for k in self.routing.get("debug_keywords", [])):
            return "debug_expert"
        if any(k.lower() in msg for k in self.routing.get("architect_keywords", [])):
            return "system_architect"
        if any(k.lower() in msg for k in self.routing.get("coach_keywords", [])):
            return "technical_coach"
        if any(k.lower() in msg for k in self.routing.get("spider_keywords", [])):
            return "knowledge_spider"
        return "technical_coach"

    def _run_rag(self, message: str) -> List[Dict[str, Any]]:
        if not self.rag_cfg.get("enabled", True):
            return []
        index_path = self.rag_cfg.get("index_path") or os.path.join(
            ROOT_DIR, "ai", "datasets", "knowledge_chunks"
        )
        top_k = int(self.rag_cfg.get("top_k", 5))
        return search_knowledge(message, top_k=top_k, knowledge_dir=index_path)

    def analyze_message(self, user_id: str, message: str) -> Dict[str, Any]:
        agent = self._select_agent(message)
        rag_results = self._run_rag(message)
        log_metric(
            agent="router",
            event_type="route_decision",
            user_id=user_id,
            meta={"selected_agent": agent, "rag_hits": len(rag_results)},
        )
        return {
            "agent": agent,
            "rag_hits": len(rag_results),
            "rag_results": rag_results,
        }

    def smart_answer(self, user_id: str, message: str) -> Dict[str, Any]:
        analysis = self.analyze_message(user_id, message)
        agent = analysis["agent"]
        rag_results = analysis["rag_results"]

        if agent == "debug_expert":
            prefix = "Debug Expert: أعطني traceback أو رسالة الخطأ بالكامل."
        elif agent == "system_architect":
            prefix = "System Architect: سأحوّل فكرتك إلى معمارية وخطوات تنفيذ."
        elif agent == "technical_coach":
            prefix = "Technical Coach: سأبني لك خطة مهارات ومهام عملية."
        elif agent == "knowledge_spider":
            prefix = "Knowledge Spider: سأبحث في المعرفة المتاحة وأجمع لك مقتطفات."
        else:
            prefix = "Generic Agent: سأساعدك قدر الإمكان."

        snippets: List[str] = []
        for r in rag_results[:3]:
            text = r.get("preview", "")
            if len(text) > 300:
                text = text[:300] + "..."
            snippets.append(text)

        parts = [prefix, "", f"سؤالك: {message}"]
        if snippets:
            parts.append("")
            parts.append("مقتطفات من الـ Knowledge:")
            for i, s in enumerate(snippets, start=1):
                parts.append(f"[{i}] {s}")
        answer = "\n".join(parts)

        log_metric(
            agent=agent,
            event_type="answer_generated",
            user_id=user_id,
            meta={"message_len": len(message), "rag_hits": len(rag_results)},
        )

        return {
            "agent": agent,
            "answer": answer,
            "analysis": {
                "rag_hits": len(rag_results),
            },
        }


if __name__ == "__main__":
    import argparse
    import json

    p = argparse.ArgumentParser()
    p.add_argument("--user-id", default="demo_user")
    p.add_argument("--message", required=True)
    a = p.parse_args()
    orch = LLMOrchestrator()
    out = orch.smart_answer(a.user_id, a.message)
    print(json.dumps(out, ensure_ascii=False, indent=2))
