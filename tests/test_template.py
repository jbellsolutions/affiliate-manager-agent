from __future__ import annotations

import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class AffiliateManagerTemplateTests(unittest.TestCase):
    def test_required_self_install_files_exist(self) -> None:
        required = [
            "README.md",
            "START-HERE.md",
            "AGENTS.md",
            "compose.yml",
            "setup.sh",
            "new-agent.sh",
            "orgo/deployment.json",
            "orgo/setup.sh",
            "orgo/sync_seed.py",
            "orgo/verify.sh",
            "orgo/connect.sh",
            "orgo/emergency-stop.sh",
            "orgo/resume-external-writes.sh",
            "orgo/AffiliateManager.desktop",
            "orgo/AffiliateManagerSetup.desktop",
            "policies/permissions.json",
            "files/SOUL.md",
            "files/AGENTS.md",
            "skills/roles/affiliate-manager/SKILL.md",
            "routines/daily-partner-pipeline.prompt",
            "routines/weekly-affiliate-scorecard.prompt",
            "docs/ORGO-SETUP.md",
            "docs/UPDATES.md",
            "scripts/verify.sh",
            "tests/smoke_deployment.sh",
            "tests/smoke_runtime.sh",
        ]
        for relative in required:
            self.assertTrue((ROOT / relative).is_file(), relative)

    def test_runtime_is_exactly_pinned(self) -> None:
        deployment = json.loads((ROOT / "orgo/deployment.json").read_text())
        runtime = deployment["runtime"]
        self.assertEqual("v2026.8.31", runtime["hermes_release"])
        self.assertEqual("0.21.0", runtime["hermes_version"])
        self.assertEqual(
            "29112bef099274229cadff79cdff7bf7b99c4b77",
            runtime["hermes_commit"],
        )
        self.assertEqual(
            "85ef536d455e51ab67aa74d79272efd49fe717597dbaadfd3cca179a905f4706",
            runtime["install_script_sha256"],
        )
        setup = (ROOT / "orgo/setup.sh").read_text()
        for value in runtime.values():
            self.assertIn(str(value), setup)
        compose = (ROOT / "compose.yml").read_text()
        self.assertIn(
            "v2026.8.31@sha256:64923faeae267792bf9bf87fe3b4c4869e35004e360c7df01730ad801b74d524",
            compose,
        )
        self.assertNotIn("image: nousresearch/hermes-agent:latest", compose)

    def test_orgo_contract_matches_current_sizing_guidance(self) -> None:
        deployment = json.loads((ROOT / "orgo/deployment.json").read_text())
        self.assertEqual("system/hermes-agent@1.0.0", deployment["orgo_template_ref"])
        self.assertEqual("affiliate-manager", deployment["computer_name"])
        self.assertGreaterEqual(deployment["hardware"]["ram_gb"], 8)
        self.assertGreaterEqual(deployment["hardware"]["cpu"], 4)

    def test_current_safety_and_reliability_defaults_are_present(self) -> None:
        config = (ROOT / "hermes/config.template.yaml").read_text()
        for required in (
            "verify_on_stop: true",
            "mode: manual",
            "cron_mode: deny",
            "hooks_auto_accept: false",
            "redact_pii: true",
            "redact_secrets: true",
            "tirith_fail_open: false",
            "hard_stop_enabled: true",
            "write_approval: true",
            "subagent_auto_approve: false",
        ):
            self.assertIn(required, config)
        setup = (ROOT / "orgo/setup.sh").read_text()
        for required in (
            "approvals.mode=manual",
            "approvals.cron_mode=deny",
            "hooks_auto_accept=false",
            "privacy.redact_pii=true",
            "security.redact_secrets=true",
            "security.tirith_fail_open=false",
            "tool_loop_guardrails.hard_stop_enabled=true",
        ):
            self.assertIn(required, setup)
        start = (ROOT / "bin/start-hermes.sh").read_text()
        self.assertNotIn("--accept-hooks", start)
        self.assertIn('HERMES_ACCEPT_HOOKS: "0"', (ROOT / "compose.yml").read_text())

    def test_permissions_keep_commercial_and_financial_authority_human(self) -> None:
        policy = json.loads((ROOT / "policies/permissions.json").read_text())
        actions = policy["actions"]
        self.assertEqual(
            "explicit-one-time-approval",
            actions["external.message_send"]["decision"],
        )
        self.assertEqual(
            "human-only",
            actions["commercial.change_terms_or_commission"]["decision"],
        )
        self.assertEqual(
            "human-only",
            actions["financial.release_payout_or_refund"]["decision"],
        )
        self.assertEqual("deny", actions["permission.self_expand"]["decision"])
        self.assertFalse(policy["standing_external_write_autonomy_enabled"])

    def test_handoff_is_beginner_first_and_complete(self) -> None:
        start = (ROOT / "START-HERE.md").read_text()
        brief = (ROOT / "AGENTS.md").read_text()
        for required in (
            "https://github.com/jbellsolutions/affiliate-manager-agent",
            "what it may cost",
            "Handle every technical step",
            "synthetic",
            "one real reply",
        ):
            self.assertIn(required, start)
        for required in (
            "Readiness briefing before changes",
            "Never ask the person to run commands",
            "Definition of done",
            "8 GB RAM, 4 vCPU",
        ):
            self.assertIn(required, brief)

    def test_instantly_workflow_has_no_automatic_send_call(self) -> None:
        daemon = (ROOT / "scripts/instantly_reply_daemon.py").read_text()
        self.assertEqual(1, daemon.count("send_reply("))
        self.assertIn("Does NOT auto-send", daemon)
        self.assertIn("AFFILIATE_MANAGER_STATE_DIR", daemon)

    def test_slack_manifest_has_agent_view_without_approval_bypass(self) -> None:
        manifest = json.loads((ROOT / "slack/manifest.example.json").read_text())
        self.assertIn("assistant_view", manifest["features"])
        self.assertIn("assistant:write", manifest["oauth_config"]["scopes"]["bot"])
        commands = {item["command"] for item in manifest["features"]["slash_commands"]}
        self.assertNotIn("/yolo", commands)
        self.assertNotIn("/update", commands)
        self.assertIn("/approve", commands)

    def test_skill_frontmatter_is_valid(self) -> None:
        skill_paths = sorted((ROOT / "skills").rglob("SKILL.md"))
        self.assertGreaterEqual(len(skill_paths), 4)
        for path in skill_paths:
            text = path.read_text()
            self.assertTrue(text.startswith("---\n"), path)
            self.assertRegex(text, r"(?m)^name: [a-z0-9-]+$")
            self.assertRegex(text, r"(?m)^description: .+$")

    def test_seed_preserves_private_edits_on_refresh(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            hermes_home = Path(temporary) / ".hermes"
            command = [
                "python3",
                str(ROOT / "orgo/sync_seed.py"),
                str(ROOT),
                str(hermes_home),
            ]
            subprocess.run(command, check=True)
            soul = hermes_home / "SOUL.md"
            soul.write_text("private owner edit\n")
            subprocess.run(command, check=True)
            self.assertEqual("private owner edit\n", soul.read_text())
            private = hermes_home / "affiliate-manager/private-business"
            self.assertTrue(private.is_dir())
            self.assertEqual(0o700, private.stat().st_mode & 0o777)
            self.assertTrue(
                (hermes_home / "skills/roles/affiliate-manager/SKILL.md").is_file()
            )

    def test_no_secret_patterns_are_committed(self) -> None:
        patterns = [
            re.compile(r"gh[opsu]_[A-Za-z0-9]{20,}"),
            re.compile(r"github_pat_[A-Za-z0-9_]{20,}"),
            re.compile(r"xox[baprs]-[A-Za-z0-9-]{20,}"),
            re.compile(r"-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----"),
            re.compile(r"sk-(?:live|test)[_-]?[A-Za-z0-9]{20,}"),
        ]
        violations: list[str] = []
        for path in ROOT.rglob("*"):
            if not path.is_file() or ".git" in path.parts or "__pycache__" in path.parts:
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            for pattern in patterns:
                if pattern.search(text) and path != Path(__file__).resolve():
                    violations.append(str(path.relative_to(ROOT)))
        self.assertEqual([], violations)


if __name__ == "__main__":
    unittest.main()
