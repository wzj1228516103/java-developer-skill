"""按 Agent 原始命令事件核对两组规则读取，不把命令数冒充文件数。"""
import argparse
import hashlib
import json
from pathlib import Path


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--results-directory", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()
root = Path(args.results_directory).resolve()
rows = []
for path in sorted(root.glob("iteration-*/*/*/outputs/agent/run/stdout.json")):
    relative = path.relative_to(root).parts
    iteration, case_id, mode = relative[:3]
    if mode not in {"with_skill", "without_skill"}:
        continue
    commands = []
    skill_reads = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("{"):
            continue
        event = json.loads(line)
        item = event.get("item", {})
        if event.get("type") != "item.completed" or item.get("type") != "command_execution":
            continue
        command = item.get("command", "")
        commands.append({"command": command, "exit_code": item.get("exit_code")})
        if "SKILL.md" in command:
            output = item.get("aggregated_output", "")
            target = any(f"name: {name}" in output for name in (
                "java-developer-skill", "java-dev", "java-review", "java-design", "java-test",
                "java-fix", "java-refactor", "java-rules"))
            skill_reads.append({"command": command, "exit_code": item.get("exit_code"),
                                "target_skill_content_returned": target,
                                "other_skill_content_returned": "name:" in output and not target})
    rows.append({
        "iteration": iteration, "case_id": case_id, "configuration": mode,
        "source_path": "/".join(relative),
        "source_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "commands": len(commands),
        "failed_commands": sum(c["exit_code"] != 0 for c in commands),
        "skill_read_attempts": len(skill_reads),
        "target_skill_read_successes": sum(s["target_skill_content_returned"] for s in skill_reads),
        "other_skill_read_successes": sum(s["other_skill_content_returned"] for s in skill_reads),
        "skill_reads": skill_reads,
    })
summary = {}
for mode in ("with_skill", "without_skill"):
    selected = [r for r in rows if r["configuration"] == mode]
    summary[mode] = {"runs": len(selected), **{
        key: sum(r[key] for r in selected) for key in (
            "commands", "failed_commands", "skill_read_attempts", "target_skill_read_successes",
            "other_skill_read_successes")}}
result = {"schema_version": "reading-footprint-v1",
          "interpretation": "只统计已完成的 shell 命令和 SKILL.md 读取尝试；一次命令可读多文件，不等同独立读取文件数。其他全局 Skill 的读取说明基线并非空白环境。没有发现目标 Skill 读取不能证明所有宿主注入均已隔离。",
          "summary": summary, "runs": rows}
destination = Path(args.output).resolve()
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(summary, ensure_ascii=False, indent=2))
