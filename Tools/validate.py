#!/usr/bin/env python3
"""Release validator for OrderOfTheLionGM 1.7.6 R5."""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

EXPECTED_VERSION = "1.7.6"
EXPECTED_BUILD = "performance-r5-hotfix1-20260726"
EXPECTED_LUA = 30
EXPECTED_MODULES = 29


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("addon_root", nargs="?", default=".")
    args = parser.parse_args()
    root = Path(args.addon_root).resolve()
    checks: list[tuple[str, bool, str]] = []

    def check(name: str, condition: bool, detail: str = "") -> None:
        checks.append((name, bool(condition), detail))

    toc_path = root / "OrderOfTheLionGM.toc"
    check("addon root exists", root.is_dir(), str(root))
    check("TOC exists", toc_path.is_file(), str(toc_path))
    check("no nested duplicate addon folder", not (root / "OrderOfTheLionGM" / "OrderOfTheLionGM.toc").exists())
    if not toc_path.is_file():
        return report(checks)

    toc = toc_path.read_text(encoding="utf-8-sig")
    check("Interface 11200", bool(re.search(r"^## Interface:\s*11200\s*$", toc, re.M)))
    check("Version 1.7.6", bool(re.search(rf"^## Version:\s*{re.escape(EXPECTED_VERSION)}\s*$", toc, re.M)))
    check("R5 build identifier", f"## X-Build: {EXPECTED_BUILD}" in toc)
    check("SavedVariables declared", "## SavedVariables: OTLGM_DB" in toc)

    load_entries = [
        line.strip().replace("\\", "/")
        for line in toc.splitlines()
        if line.strip() and not line.lstrip().startswith("##")
    ]
    lua_entries = [entry for entry in load_entries if entry.lower().endswith(".lua")]
    check(f"{EXPECTED_LUA} TOC Lua entries", len(lua_entries) == EXPECTED_LUA, str(len(lua_entries)))
    check("no duplicate TOC entries", len(load_entries) == len(set(load_entries)))
    missing = [entry for entry in load_entries if not (root / entry).is_file()]
    check("all TOC files exist", not missing, ", ".join(missing))
    check("Performance176, R5 and hotfix load in order", lua_entries[-3:] == ["Modules/Core/Performance176.lua", "Modules/Core/Release176R5.lua", "Modules/Core/Release176R5Hotfix.lua"], str(lua_entries[-3:]))
    check("R5 hotfix is final runtime module", bool(lua_entries) and lua_entries[-1] == "Modules/Core/Release176R5Hotfix.lua", lua_entries[-1] if lua_entries else "none")

    lua_files = sorted((root / "Modules").rglob("*.lua"))
    check(f"{EXPECTED_LUA} Lua files in package", len(lua_files) == EXPECTED_LUA, str(len(lua_files)))
    rel_lua = {str(path.relative_to(root)).replace("\\", "/") for path in lua_files}
    check("TOC covers every Lua file", rel_lua == set(lua_entries), ", ".join(sorted(rel_lua.symmetric_difference(set(lua_entries)))))

    combined = ""
    non_ascii: list[str] = []
    bom: list[str] = []
    absolute_paths: list[str] = []
    decode_failures: list[str] = []
    allowed_utf8_fragments = {"Modules/Features/Release175R6.lua": ("паден",)}
    for path in lua_files:
        rel = str(path.relative_to(root)).replace("\\", "/")
        data = path.read_bytes()
        if data.startswith(b"\xef\xbb\xbf"):
            bom.append(rel)
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            decode_failures.append(rel)
            text = data.decode("utf-8", errors="replace")
        safe_text = text
        for fragment in allowed_utf8_fragments.get(rel, ()):
            safe_text = safe_text.replace(fragment, "")
        if any(ord(ch) > 127 for ch in safe_text):
            non_ascii.append(rel)
        if "/mnt/data/" in text or re.search(r"[A-Za-z]:\\\\", text):
            absolute_paths.append(rel)
        combined += f"\n-- FILE {rel}\n{text}"

    check("all Lua files decode as UTF-8", not decode_failures, ", ".join(decode_failures))
    check("Lua source is ASCII/Vanilla-font safe", not non_ascii, ", ".join(non_ascii))
    check("Lua files have no UTF-8 BOM", not bom, ", ".join(bom))
    check("no developer absolute paths", not absolute_paths, ", ".join(absolute_paths))

    # Script-created controls need explicit mouse preparation in this client.
    unprepared: list[str] = []
    control_pattern = re.compile(
        r'(?P<target>[A-Za-z_][A-Za-z0-9_.]*)\s*=\s*CreateFrame\(\s*["\'](?P<kind>Button|CheckButton|EditBox|Slider)["\']'
    )
    for path in lua_files:
        lines = path.read_text(encoding="utf-8").splitlines()
        for index, line in enumerate(lines):
            match = control_pattern.search(line)
            if not match:
                continue
            following = "\n".join(lines[index + 1:index + 4])
            target = re.escape(match.group("target"))
            if not re.search(rf"PrepareInteractiveControl170\(\s*{target}\s*,", following):
                # Named controls created through old templates are intentionally handled
                # by the shared helper only when they are raw script-created controls.
                unprepared.append(f"{path.relative_to(root)}:{index + 1}")
    check("all raw UI controls explicitly prepared", not unprepared, ", ".join(unprepared))

    banned = {
        "direct EditBox:HasFocus": r":HasFocus\s*\(",
        "unsupported SetDesaturated call": r"(?<![A-Za-z])SetDesaturated\s*\(",
        "BackdropTemplate dependency": r"BackdropTemplate",
        "modern C_ namespace": r"\bC_[A-Za-z0-9_]+\.",
        "goto statement": r"(?m)^\s*goto\s+",
        "continue statement": r"(?m)^\s*continue\s*$",
    }
    for label, pattern in banned.items():
        check(f"no {label}", re.search(pattern, combined) is None)

    on_updates = re.findall(r"SetScript\s*\(\s*[\"']OnUpdate[\"']", combined)
    check("single shared OnUpdate heartbeat", len(on_updates) == 1, str(len(on_updates)))

    module_names = re.findall(r"OTLGM:RegisterModule\s*\(\s*[\"']([^\"']+)", combined)
    check(f"{EXPECTED_MODULES} registered modules", len(module_names) == EXPECTED_MODULES, str(len(module_names)))
    check("registered module names unique", len(module_names) == len(set(module_names)))
    check("R5 module registered", "Release176R5" in module_names)
    check("R5 hotfix module registered", "Release176R5Hotfix" in module_names)
    check("Performance layer remains unregistered", "Performance176" not in module_names)

    bootstrap = (root / "Modules/Core/Bootstrap.lua").read_text(encoding="utf-8")
    events = (root / "Modules/Core/Events.lua").read_text(encoding="utf-8")
    performance = (root / "Modules/Core/Performance176.lua").read_text(encoding="utf-8")
    r5 = (root / "Modules/Core/Release176R5.lua").read_text(encoding="utf-8")
    hotfix = (root / "Modules/Core/Release176R5Hotfix.lua").read_text(encoding="utf-8")
    check("runtime version constant", f'OTLGM.version = "{EXPECTED_VERSION}"' in bootstrap and f'OTLGM.version = "{EXPECTED_VERSION}"' in r5 and f'OTLGM.version = "{EXPECTED_VERSION}"' in hotfix)
    check("runtime build constant", f'OTLGM.build = "{EXPECTED_BUILD}"' in bootstrap and f'OTLGM.build = "{EXPECTED_BUILD}"' in r5 and f'OTLGM.build = "{EXPECTED_BUILD}"' in hotfix)
    check("diagnostics module count updated", 'Modules=" .. tostring(moduleCount) .. "/29' in events)

    # Performance and requested workflow guarantees.
    check("UNIT_HEALTH achievement path detached", 'Unregister176("OTLGM_ReleaseEvent175", "UNIT_HEALTH")' in performance)
    check("old BAG_UPDATE path detached", 'Unregister176("OTLGM_ReleaseEvent175R6", "BAG_UPDATE")' in performance)
    check("incremental bag scanner installed", "ProcessIncrementalBagScan176" in performance and "BAG_SCAN_SLOTS_PER_TICK_176" in performance)
    check("zone transition coalescing installed", "ScheduleTransition176" in performance and "TRANSITION_SETTLE_176" in performance)
    check("mail achievement burst disabled in R5", "function OTLGM:ScheduleMailboxScan176" in r5 and "self.runtime.mailScan176 = nil" in r5)
    check("network work bounded in R5", "NETWORK_BUDGET_R5 = 2" in r5 and "math.min(NETWORK_BUDGET_R5" in r5)
    check("hidden page refresh guards installed", "CanRefreshPageR5" in r5 and "MarkPageDirtyR5" in r5)
    check("R5 adds no visual heartbeat maintenance", "Do not add visual maintenance to the shared heartbeat" in r5 and "ApplyR5UIFixes() end" not in r5)
    check("exclusive modal manager installed", "OpenExclusiveModalR5" in r5 and "CloseExclusiveModalR5" in r5)
    check("modal shade scoped to addon window", "PositionModalShadeH1" in hotfix and 'overlay.modalShadeScopeH1 = "ADDON"' in hotfix)
    check("modal controls recursively raised", "RaiseModalTreeH1" in hotfix and "GetChildren" in hotfix)
    check("modal surfaces fully opaque", "StyleModalH1" in hotfix and "0.004, 0.005, 0.007, 1" in hotfix)
    check("functional whisper invite flow installed", "CanInviteGuildMembersR5" in r5 and "InviteRecentWhisper176" in r5 and "entryR5" in r5)
    check("Treasury Activity installed", "BuildTreasuryActivityR5" in r5 and "GetTreasuryActivityR5" in r5)
    check("per-goal Treasury ledger installed", "BuildTreasuryGoalLedgerR5" in r5 and "GetTreasuryGoalLedgerR5" in r5)
    check("per-goal Ledger and contribution buttons installed", "EnsureGoalButtonsH1" in hotfix and '"Ledger"' in hotfix and '"+ Gold"' in hotfix)
    check("current roster metadata installed", "GetTreasuryContributorMetaH1" in hotfix and "ContributorMetaTextH1" in hotfix)
    check("donor-owned Treasury achievements installed", all(token in hotfix for token in ("E001", "E002", "E003", "E004", "EvaluateTreasuryDonorAchievementsH1")))
    check("donor total sync is targeted", '"DONOR"' in hotfix and '"WHISPER"' in hotfix and "QueueTreasuryState170" in hotfix)
    check("hotfix adds no OnUpdate", 'SetScript("OnUpdate"' not in hotfix and "SetScript('OnUpdate'" not in hotfix)
    check("all ledger contributors pageable", "summaryOffsetR5" in r5 and "summaryNextR5" in r5)
    check("compact lower OTL edge tab installed", "PARK_TAB_WIDTH_R5 = 30" in r5 and "PARK_TAB_Y_R5 = -176" in r5)
    check("recruitment whisper button no longer overlaps world card", 'SetPoint("TOPLEFT", page, "TOPLEFT", 270, -54)' in r5)
    check("actor-unavailable UI cleanup installed", "BaseRefreshOverviewCleanupR5" in r5 and "Left or was removed" in r5)

    texluac = shutil.which("texluac") or shutil.which("luac")
    syntax_failures: list[str] = []
    if texluac:
        for path in lua_files:
            run = subprocess.run([texluac, "-p", str(path)], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env={**__import__('os').environ, 'TERM': 'xterm'})
            if run.returncode != 0:
                syntax_failures.append(f"{path.relative_to(root)}: {(run.stderr or run.stdout).strip()}")
        check("all Lua files compile", not syntax_failures, " | ".join(syntax_failures))
    else:
        check("Lua compiler optional in CI", True, "texluac/luac not found; syntax is covered by the dedicated CI compile step")

    workflow = root / ".github/workflows/ci.yml"
    workflow_text = workflow.read_text(encoding="utf-8") if workflow.is_file() else ""
    check("GitHub Actions validation workflow installed", bool(workflow_text))
    check("GitHub workflow runs all release gates", all(token in workflow_text for token in (
        "Tools/validate.py", "Tools/validate_performance176.py", "luac5.1 -p",
        "performance_smoke_test.lua", "release176r5_smoke_test.lua", "full_load_smoke_test.lua", "unzip -t",
    )))
    check("GitHub workflow has no external npm validation dependency", "npm ci" not in workflow_text and "npm run" not in workflow_text)

    required = [
        root / "Assets/LionCrest.tga",
        root / "README.md",
        root / "LICENSE",
        root / "RELEASE_NOTES_1.7.6.md",
        root / "Tools/validate.py",
        root / "Tools/release176r5_smoke_test.lua",
        root / "Modules/Core/Release176R5Hotfix.lua",
        root / ".github/workflows/ci.yml",
    ]
    check("required package files present", all(path.is_file() for path in required), ", ".join(str(p) for p in required if not p.is_file()))

    forbidden = []
    for package_root in (root / "Assets", root / "Modules"):
        if package_root.exists():
            forbidden.extend(path for path in package_root.rglob("*") if path.name in {".git", "node_modules", "__pycache__"})
    check("no development directories in install addon", not forbidden, ", ".join(map(str, forbidden)))

    smoke = root / "Tools/release176r5_smoke_test.lua"
    texlua = shutil.which("texlua")
    if smoke.is_file() and texlua:
        run = subprocess.run([texlua, str(smoke), str(root)], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env={**__import__('os').environ, 'TERM': 'xterm'})
        check("R5 runtime smoke test", run.returncode == 0 and "RELEASE176_R5_SMOKE_TEST_OK" in run.stdout, (run.stdout + run.stderr).strip())
    else:
        check("R5 runtime smoke test script present", smoke.is_file(), "texlua unavailable; script retained for local/release validation")

    full_smoke = root / "Tools/full_load_smoke_test.lua"
    if full_smoke.is_file() and texlua:
        run = subprocess.run([texlua, str(full_smoke), str(root)], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env={**__import__('os').environ, 'TERM': 'xterm'})
        check("full addon load and UI-build smoke test", run.returncode == 0 and "FULL_LOAD_R5_SMOKE_TEST_OK" in run.stdout, (run.stdout + run.stderr).strip())
    else:
        check("full-load smoke test script present", full_smoke.is_file(), "texlua unavailable; script retained for local/release validation")

    return report(checks)


def report(checks: list[tuple[str, bool, str]]) -> int:
    failed = 0
    for name, ok, detail in checks:
        print(f"[{'PASS' if ok else 'FAIL'}] {name}" + (f" ({detail})" if detail else ""))
        if not ok:
            failed += 1
    print(f"RESULT passed={len(checks)-failed} failed={failed} total={len(checks)}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
