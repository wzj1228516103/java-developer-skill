"""校验真实 YAML 解析后的关键评分契约；需要 PyYAML。"""
from pathlib import Path
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[2]


class EvaluationConfigTests(unittest.TestCase):
    def test_plain_hash_scalar_demonstrates_truncation(self):
        parsed = yaml.safe_load("criterion: 使用 #{id} 绑定；考虑 Long")
        self.assertEqual("使用", parsed["criterion"])

    def test_quoted_hash_scalar_preserves_contract(self):
        parsed = yaml.safe_load("criterion: '使用 #{id} 绑定；考虑 Long'")
        self.assertEqual("使用 #{id} 绑定；考虑 Long", parsed["criterion"])

    def test_security_judge_keeps_parameter_binding_and_exploitability(self):
        case = yaml.safe_load(
            (ROOT / "evals/cases/security-review.yaml").read_text(encoding="utf-8")
        )
        criteria = case["judge"]["criteria"]
        sql = [item for item in criteria if "${id}" in item]
        self.assertEqual(1, len(sql))
        for requirement in ("#{id}", "值绑定", "Long", "不直接", "已证实事实"):
            self.assertIn(requirement, sql[0])

    def test_all_declared_cases_resolve_and_semantic_criteria_are_strings(self):
        for config_name in ("eval.yaml", "holdout.yaml", "transaction-regression.yaml"):
            config = yaml.safe_load((ROOT / "evals" / config_name).read_text(encoding="utf-8"))
            ids = set()
            for filename in config["cases"]["files"]:
                case = yaml.safe_load((ROOT / filename).read_text(encoding="utf-8"))
                self.assertEqual(Path(filename).stem, case["id"])
                self.assertNotIn(case["id"], ids)
                ids.add(case["id"])
                if case["judge"]["type"] == "agent_judge":
                    for criterion in case["judge"]["criteria"]:
                        self.assertIsInstance(criterion, str)
                        self.assertTrue(criterion.strip())

    def test_calibration_samples_reference_current_rubric_ids(self):
        import json
        samples = json.loads(
            (ROOT / "evals/fixtures/holdout-judge-calibration.json").read_text(encoding="utf-8")
        )["samples"]
        self.assertEqual(len(samples), len({sample["id"] for sample in samples}))
        for sample in samples:
            case = yaml.safe_load(
                (ROOT / f"evals/cases/{sample['case_id']}.yaml").read_text(encoding="utf-8")
            )
            ids = {f"criterion-{i}" for i in range(1, len(case["judge"]["criteria"]) + 1)}
            self.assertTrue(set(sample["expected"]).issubset(ids))
            self.assertTrue(sample["answer"].strip())


if __name__ == "__main__":
    unittest.main(verbosity=2)
