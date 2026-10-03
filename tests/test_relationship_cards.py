"""Relationship cards on the Orgo install: the sample program imported through orgo/relationship.sh, the relcore MCP
server in drafts-only mode, and the permission map. relcore itself is tested in True Revenue Partner, where it is built."""
from __future__ import annotations

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SAMPLE = ROOT / "examples" / "relationship"
BANNED = re.compile(r"approve|send|sign|decide|release|resume|purge|unsuppress")


class RelationshipCards(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tmp = Path(tempfile.mkdtemp(prefix="affiliate-cards-"))
        cls.env = {**os.environ, "HOME": str(cls.tmp), "HERMES_HOME": str(cls.tmp / ".hermes"),
                   "RELCORE_NOW": "2026-10-01T15:00:00Z"}
        for k in ("RELCORE_MODE", "RELCORE_ROOT", "RELCORE_HOME", "RELCORE_VAULT", "RELCORE_BASE", "AFFILIATE_VAULT"):
            cls.env.pop(k, None)
        cls.run_cli("init")
        cls.imported = cls.run_cli("import", "apply", "csv", str(SAMPLE), "--client", "Northwind Outdoor Gear")
        cls.vault = cls.tmp / "AffiliateVault"
        settings = dict(line.split("=", 1) for line in cls.run_cli("env").splitlines())
        cls.mcp_env = {**cls.env, **settings}

    @classmethod
    def run_cli(cls, *args: str) -> str:
        out = subprocess.run([str(ROOT / "orgo" / "relationship.sh"), *args], env=cls.env, capture_output=True, text=True)
        if out.returncode:
            raise AssertionError(f"relationship.sh {' '.join(args)} failed:\n{out.stdout}\n{out.stderr}")
        return out.stdout

    def mcp(self, calls: list[tuple[str, dict]]) -> list[dict]:
        p = subprocess.Popen([sys.executable, "-m", "relcore.mcp_server", "--mode", "plugin"], env=self.mcp_env, cwd=ROOT,
                             stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        replies = []
        try:
            for i, (method, params) in enumerate([("initialize", {"protocolVersion": "2025-06-18"}), *calls], 1):
                p.stdin.write(json.dumps({"jsonrpc": "2.0", "id": i, "method": method, "params": params}) + "\n")
                p.stdin.flush()
                replies.append(json.loads(p.stdout.readline()))
        finally:
            p.stdin.close()
            p.wait(timeout=30)
            p.stdout.close()
            p.stderr.close()
        return replies[1:]

    def card(self, folder: str, name: str) -> str:
        [path] = list((self.vault / folder).glob(f"{name} (*).md"))
        return path.read_text()

    def test_every_person_partner_and_partnership_has_a_card(self) -> None:
        self.assertEqual(len(list((self.vault / "People").glob("*.md"))), 7)
        self.assertEqual(len(list((self.vault / "Partnerships").glob("*.md"))), 6)
        self.assertGreaterEqual(len(list((self.vault / "Partners").glob("*.md"))), 6)
        ps = next((self.vault / "Partnerships").glob("Northwind Outdoor Gear x Trail Notes - F1.A.1 *.md")).read_text()
        self.assertIn("Niche blogger", ps)
        self.assertIn("[[People/Ava Brooks", ps)

    def test_record_lists_become_restrictions_and_exclusions(self) -> None:
        ps = next((self.vault / "Partnerships").glob("Northwind Outdoor Gear x Camp Deals - F1.B.1 *.md")).read_text()
        self.assertIn("left out of waves: active producer", ps)
        self.assertIn("do not contact", self.card("People", "Kim Tran").lower())

    def test_warm_introduction_is_on_the_graph(self) -> None:
        self.assertIn("Introduced by", self.card("People", "Jen Okafor"))

    def test_mcp_server_is_drafts_only(self) -> None:
        listed, ctx, wave = self.mcp([("tools/list", {}),
                                      ("tools/call", {"name": "rel_context", "arguments": {"ref": {"email": "ava@trailnotes.example.com"}}}),
                                      ("tools/call", {"name": "rel_wave_prepare", "arguments": {}})])
        names = [t["name"] for t in listed["result"]["tools"]]
        self.assertIn("rel_context", names)
        self.assertIn("rel_sent_record", names)
        self.assertIn("rel_reply_record", names)
        self.assertFalse([n for n in names if BANNED.search(n)], names)
        text = ctx["result"]["content"][0]["text"]
        self.assertIn("## WHO", text)
        self.assertIn("context_digest: ", text)
        result = wave["result"]
        self.assertFalse(result["isError"], result)
        aid = result["structuredContent"]["action_id"]
        self.assertTrue(aid, result)
        self.assertTrue((self.tmp / ".hermes" / "affiliate-manager" / "private-business" / "outbox" / f"{aid}.md").is_file())
        self.assertFalse(Path("/var/lib/relcore/spool/prepared", f"{aid}.json").exists())

    def test_every_relationship_tool_is_mapped_at_tier_one_or_below(self) -> None:
        policy = json.loads((ROOT / "policies" / "permissions.json").read_text())
        for tool, action in policy["relationship_tools"].items():
            if tool.startswith("_"):
                continue
            self.assertIn(action, policy["actions"], tool)
            self.assertLessEqual(policy["actions"][action]["tier"], 1, tool)

    def test_setup_registers_the_server_and_no_sender(self) -> None:
        setup = (ROOT / "orgo" / "setup.sh").read_text()
        self.assertIn("mcp_servers.relcore.command", setup)
        self.assertNotIn("relsend", setup)
        self.assertNotIn("relapprove", setup)


if __name__ == "__main__":
    unittest.main()
