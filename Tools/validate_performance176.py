#!/usr/bin/env python3
from __future__ import annotations
import hashlib
import re
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
lua = root / 'Modules/Core/Performance176.lua'
toc = root / 'OrderOfTheLionGM.toc'
checks: list[tuple[str, bool, str]] = []

def check(name: str, ok: bool, detail: str = '') -> None:
    checks.append((name, bool(ok), detail)
)

check('TOC exists', toc.is_file(), str(toc))
check('performance module exists', lua.is_file(), str(lua))
if toc.is_file():
    toc_text = toc.read_text('utf-8-sig')
    check('version 1.7.6', bool(re.search(r'^## Version:\s*1\.7\.6\s*$', toc_text, re.M)))
    check('R5 package build id', '## X-Build: performance-r5-hotfix1-20260726' in toc_text)
    entries = [x.strip().replace('\\','/') for x in toc_text.splitlines() if x.strip() and not x.startswith('##')]
    check('performance module loaded before R5 hotfix chain', len(entries) >= 3 and entries[-3:] == ['Modules/Core/Performance176.lua','Modules/Core/Release176R5.lua','Modules/Core/Release176R5Hotfix.lua'], str(entries[-3:]))
    check('no duplicate TOC entries', len(entries) == len(set(entries)), str(len(entries)))

if lua.is_file():
    data = lua.read_bytes()
    text = data.decode('utf-8')
    check('no UTF-8 BOM', not data.startswith(b'\xef\xbb\xbf'))
    check('ASCII-safe Lua source', all(b < 128 for b in data))
    check('no additional OnUpdate', 'SetScript("OnUpdate"' not in text and "SetScript('OnUpdate'" not in text)
    check('no modern C_ API', re.search(r'\bC_[A-Za-z0-9_]+\.', text) is None)
    check('no goto/continue', re.search(r'\b(goto|continue)\b', text) is None)
    check('R4 performance-layer identity', 'OTLGM.build = "performance-r4-ultrasafe-20260725"' in text and 'revision = 4' in text and 'P176.revision = 4' in text)
    check('UNIT_HEALTH detached', 'Unregister176("OTLGM_ReleaseEvent175", "UNIT_HEALTH")' in text)
    check('all duplicate world-entry frames detached', all(token in text for token in (
        'Unregister176("OTLGM_AchievementsEvent174", "PLAYER_ENTERING_WORLD")',
        'Unregister176("OTLGM_ReleaseEvent175R4", "PLAYER_ENTERING_WORLD")',
        'Unregister176("OTLGM_ReleaseEvent175R6", "PLAYER_ENTERING_WORLD")',
        'Unregister176("OTLGM_EventFrame", "PLAYER_ENTERING_WORLD")')))
    check('R6 zone full-scan path detached', 'Unregister176("OTLGM_ReleaseEvent175R6", "ZONE_CHANGED_NEW_AREA")' in text)
    check('same-zone minimap guard installed', 'sameZoneMinimapIgnored' in text and 'if real == lastReal then' in text)
    check('stable transition pass installed', 'TRANSITION_SETTLE_176 = 3' in text and 'RunStableTransition176' in text)
    check('transition queue pause installed', all(x in text for x in ('BaseTransitionNetwork176','BaseTransitionCrafting176','BaseTransitionTreasury176')))
    check('incremental bag scanner active', 'BAG_SCAN_SLOTS_PER_TICK_176 = 10' in text and 'ProcessIncrementalBagScan176' in text)
    check('old R6 BAG_UPDATE detached', 'Unregister176("OTLGM_ReleaseEvent175R6", "BAG_UPDATE")' in text)
    check('bag achievements finalized', all(x in text for x in ('coreClothStacksR6','uniqueFoodR6','uniquePotionsR6','D015','D016','D017')))
    check('capital money checks retained', 'thunderbluff=true' in text and 'moneyCopperR6' in text and 'D019' in text)
    check('achievement cache replacement guard', 'liveStore == cache.db' in text)
    check('per-frame debounce throttled', 'UI_DEBOUNCE_VISIBLE_176' in text and 'BaseProcessUIDebounce176' in text)
    check('idle queue guards installed', all(x in text for x in ('emptyNetworkTicks','emptyCraftingTicks','emptyTreasuryTicks')))
    check('group snapshot cache installed', 'BaseGetGroupSnapshot176' in text and 'groupSnapshotHits' in text)
    check('database cache replacement guard', 'current == cache.db' in text and 'cached.guildDb == guildDb' in text)
    check('maintenance reduced', 'BACKGROUND_MAINTENANCE_176 = 300' in text)

    check('R6 cold login detached', 'Unregister176("OTLGM_ReleaseEvent175R6", r4EventName176)' in text and '"PLAYER_LOGIN"' in text)
    check('R4 threshold login detached', 'Unregister176("OTLGM_ReleaseEvent175R4", "PLAYER_LOGIN")' in text)
    check('mailbox burst guarded', 'MAIL_HEADERS_PER_TICK_176 = 4' in text and 'ProcessMailboxScan176' in text)
    check('risky achievement trackers paused', all(x in text for x in ('D003','D004','D005','D006','D008','D009','D010','D012','D018','D021','PauseAchievementTracker176')))
    check('cold-start work queue installed', 'ProcessDeferredColdStartWork176' in text and 'COLD_LOGIN_WINDOW_176 = 30' in text)
    check('window park commands installed', 'function OTLGM:ParkWindow176' in text and 'msg == "center"' in text and 'SetClampedToScreen(false)' in text)
    check('first UI refresh delayed', 'uiBuildDeferredRefresh' in text and 'uiRefreshDue176' in text)
    try:
        proc = subprocess.run(['texluac','-p',str(lua)], text=True, capture_output=True, timeout=20)
        check('Lua syntax via texluac', proc.returncode == 0, (proc.stdout + proc.stderr).strip())
    except Exception as exc:
        check('Lua syntax via texluac', False, str(exc))
    check('module SHA-256', True, hashlib.sha256(data).hexdigest())

smoke = root / 'Tools/performance_smoke_test.lua'
check('smoke test exists', smoke.is_file(), str(smoke))
if smoke.is_file() and lua.is_file():
    try:
        proc = subprocess.run(['texlua',str(smoke),str(lua)], cwd=root, text=True, capture_output=True, timeout=30)
        check('runtime smoke test', proc.returncode == 0 and 'PERFORMANCE176_R4_SMOKE_TEST_OK' in proc.stdout, (proc.stdout + proc.stderr).strip())
    except Exception as exc:
        check('runtime smoke test', False, str(exc))

failed = 0
for name, ok, detail in checks:
    print(f"[{'PASS' if ok else 'FAIL'}] {name}" + (f' ({detail})' if detail else ''))
    if not ok: failed += 1
print(f'RESULT passed={len(checks)-failed} failed={failed} total={len(checks)}')
sys.exit(1 if failed else 0)
