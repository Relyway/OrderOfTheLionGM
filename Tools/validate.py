#!/usr/bin/env python3
"""Static release validator for OrderOfTheLionGM 1.7.5."""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


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
    if not toc_path.is_file():
        return report(checks)

    toc = toc_path.read_text(encoding="utf-8-sig")
    check("Interface 11200", bool(re.search(r"^## Interface:\s*11200\s*$", toc, re.M)))
    check("Version 1.7.5", bool(re.search(r"^## Version:\s*1\.7\.5\s*$", toc, re.M)))
    check("stable build identifier", "## X-Build: stable-r7-20260723" in toc)
    check("SavedVariables declared", "## SavedVariables: OTLGM_DB" in toc)

    load_entries = [
        line.strip().replace("\\", "/")
        for line in toc.splitlines()
        if line.strip() and not line.lstrip().startswith("##")
    ]
    lua_entries = [entry for entry in load_entries if entry.lower().endswith(".lua")]
    check("27 TOC Lua entries", len(lua_entries) == 27, str(len(lua_entries)))
    check("no duplicate TOC entries", len(load_entries) == len(set(load_entries)))
    missing = [entry for entry in load_entries if not (root / entry).is_file()]
    check("all TOC files exist", not missing, ", ".join(missing))

    lua_files = sorted((root / "Modules").rglob("*.lua"))
    check("27 Lua files in package", len(lua_files) == 27, str(len(lua_files)))
    check(
        "TOC covers every Lua file",
        {
            str(path.relative_to(root)).replace("\\", "/")
            for path in lua_files
        }
        == set(lua_entries),
    )

    combined = ""
    non_ascii: list[str] = []
    bom: list[str] = []
    absolute_paths: list[str] = []

    # This exact UTF-8 fragment is intentionally used only to recognize
    # localized falling-damage combat text. It is never displayed by the addon.
    allowed_utf8_fragments = {
        "Modules/Features/Release175R6.lua": ("паден",),
    }

    for path in lua_files:
        data = path.read_bytes()
        rel = str(path.relative_to(root)).replace("\\", "/")
        if data.startswith(b"\xef\xbb\xbf"):
            bom.append(rel)

        text = data.decode("utf-8", errors="replace")
        ascii_check_text = text
        for fragment in allowed_utf8_fragments.get(rel, ()):
            ascii_check_text = ascii_check_text.replace(fragment, "")

        if any(ord(character) > 127 for character in ascii_check_text):
            non_ascii.append(rel)

        if "/mnt/data/" in text or re.search(r"[A-Za-z]:\\\\", text):
            absolute_paths.append(rel)
        combined += f"\n-- FILE {rel}\n{text}"

    check(
        "Lua source is ASCII/Vanilla-font safe",
        not non_ascii,
        ", ".join(non_ascii),
    )
    check("Lua files have no UTF-8 BOM", not bom, ", ".join(bom))
    check("no developer absolute paths", not absolute_paths, ", ".join(absolute_paths))

    # Every raw script-created actionable control must opt in to mouse input.
    # OctoWoW/Vanilla does not provide consistent defaults for bare frames.
    unprepared_controls: list[str] = []
    control_pattern = re.compile(
        r'(?P<target>[A-Za-z_][A-Za-z0-9_.]*)\s*=\s*CreateFrame\(\s*["\']'
        r'(?P<kind>Button|CheckButton|EditBox|Slider)["\']'
    )
    for path in lua_files:
        lines = path.read_text(encoding="utf-8").splitlines()
        for index, line in enumerate(lines):
            match = control_pattern.search(line)
            if not match:
                continue
            following = "\n".join(lines[index + 1:index + 3])
            target = re.escape(match.group("target"))
            if not re.search(
                rf"PrepareInteractiveControl170\(\s*{target}\s*,",
                following,
            ):
                unprepared_controls.append(
                    f"{path.relative_to(root)}:{index + 1}"
                )
    check(
        "all raw UI controls explicitly prepared",
        not unprepared_controls,
        ", ".join(unprepared_controls),
    )

    banned_patterns = {
        "direct EditBox:HasFocus": r":HasFocus\s*\(",
        "unsupported SetDesaturated call": r"(?<![A-Za-z])SetDesaturated\s*\(",
        "BackdropTemplate dependency": r"BackdropTemplate",
        "modern C_ namespace": r"\bC_[A-Za-z0-9_]+\.",
        "removed Quick Lion Menu": r"quickMenu170|quickLionButton170|Quick Lion",
    }
    for label, pattern in banned_patterns.items():
        check(f"no {label}", re.search(pattern, combined) is None)

    on_updates = re.findall(r"SetScript\s*\(\s*[\"']OnUpdate[\"']", combined)
    check("single shared OnUpdate heartbeat", len(on_updates) == 1, str(len(on_updates)))

    module_names = re.findall(
        r"OTLGM:RegisterModule\s*\(\s*[\"']([^\"']+)",
        combined,
    )
    check("27 registered modules", len(module_names) == 27, str(len(module_names)))
    check(
        "registered module names unique",
        len(module_names) == len(set(module_names)),
    )

    bootstrap = (root / "Modules/Core/Bootstrap.lua").read_text(encoding="utf-8")
    database = (root / "Modules/Core/Database.lua").read_text(encoding="utf-8")
    search = (root / "Modules/Crafting/Search.lua").read_text(encoding="utf-8")
    events = (root / "Modules/Core/Events.lua").read_text(encoding="utf-8")
    transport = (root / "Modules/Network/Transport.lua").read_text(encoding="utf-8")
    security = (root / "Modules/Network/Security.lua").read_text(encoding="utf-8")

    theme = (root / "Modules/UI/Theme.lua").read_text(encoding="utf-8")
    main_ui = (root / "Modules/UI/Main.lua").read_text(encoding="utf-8")
    pages_ui = (root / "Modules/UI/Pages.lua").read_text(encoding="utf-8")
    experience_ui = (root / "Modules/UI/Experience.lua").read_text(encoding="utf-8")
    coordination_ui = (
        root / "Modules/Integration/Coordination.lua"
    ).read_text(encoding="utf-8")

    check("runtime version constant", 'OTLGM.version = "1.7.5"' in bootstrap)
    check(
        "runtime build constant",
        'OTLGM.build = "stable-r7-20260723"' in bootstrap,
    )
    check(
        "central interaction repair installed",
        "PrepareInteractiveControl170" in theme
        and "RepairInteractiveTree170" in theme,
    )
    check(
        "all UI generations share enabled-state setter",
        "SetControlEnabled170(button, enabled, reason)" in main_ui
        and "SetControlEnabled170(button, enabled, reason)" in pages_ui
        and "SetControlEnabled170(button, enabled, reason)" in experience_ui
        and "SetControlEnabled170(button, enabled ~= false, reason)"
        in coordination_ui,
    )
    check(
        "runtime schema constant",
        "OTLGM.schemaVersion = 14" in bootstrap
        and "local ROOT_SCHEMA = 14" in database,
    )
    check(
        "root shape repair installed",
        "EnsureRootShape170" in database
        and "EnsureGuildContainers170" in database,
    )
    check(
        "Favorites included in crafting cache key",
        "craftingFavoritesOnly170" in search,
    )
    check(
        "level basis included in crafting cache key",
        "craftingLevelBasis170" in search,
    )
    check(
        "temporary status expiry is heartbeat driven",
        "ProcessStatus170" in events,
    )
    check("network queue supports coalescing", "coalesceKey" in transport)
    check(
        "targeted non-recipient skip metric",
        "targetedSkipped" in security,
    )
    check(
        "transport is sole addon-message sender",
        combined.count("pcall(SendAddonMessage") == 1,
    )
    check(
        "outbound chat escape sanitizer installed",
        "NormalizeWirePayload172" in transport
        and "outboundSanitized172" in transport,
    )
    check(
        "presence protocol no longer sends raw pipes",
        '"V|" .. self.version' not in combined
        and '"Q|" .. self.version' not in combined,
    )
    check(
        "announcement read receipts installed",
        "RecordAnnouncementReadReceipt172" in combined
        and "readersButton172" in combined,
    )

    required_files = [
        root / "Assets/LionCrest.tga",
        root / "README.md",
        root / "LICENSE",
    ]
    check(
        "required package files present",
        all(path.is_file() for path in required_files),
    )
    forbidden = []
    for package_root in (root / "Assets", root / "Modules"):
        if package_root.exists():
            forbidden.extend(
                path
                for path in package_root.rglob("*")
                if path.name in {".git", "node_modules", "__pycache__"}
            )
    check(
        "no development directories in install addon",
        not forbidden,
        ", ".join(map(str, forbidden)),
    )

    return report(checks)


def report(checks: list[tuple[str, bool, str]]) -> int:
    failed = 0
    for name, ok, detail in checks:
        status = "PASS" if ok else "FAIL"
        suffix = f" ({detail})" if detail else ""
        print(f"[{status}] {name}{suffix}")
        if not ok:
            failed += 1
    print(
        f"RESULT passed={len(checks) - failed} "
        f"failed={failed} total={len(checks)}"
    )
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
