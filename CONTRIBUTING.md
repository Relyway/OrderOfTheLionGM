# Contributing

OrderOfTheLionGM is maintained primarily for the Order of the Lion guild on OctoWoW.

## Requirements

- Preserve compatibility with the Vanilla-style client (`Interface 11200`).
- Use Lua 5.1-compatible syntax.
- Do not add permanent polling or extra `OnUpdate` handlers without a documented need.
- Keep SavedVariables migrations backward-compatible.
- Do not change the network protocol or schema without explicit migration handling.
- Test UI controls through the real click gate, not only by directly invoking `OnClick`.

## Local checks

On Debian/Ubuntu, install the test runtime first:

```bash
sudo apt-get install -y lua5.1 zip unzip rsync
```

Then run:

```bash
python3 Tools/validate.py .
python3 Tools/validate_performance176.py .
while IFS= read -r file; do luac5.1 -p "$file"; done < <(grep -v '^##' OrderOfTheLionGM.toc | sed '/^[[:space:]]*$/d' | tr '\\' '/')
lua5.1 Tools/performance_smoke_test.lua Modules/Core/Performance176.lua
lua5.1 Tools/release176r5_smoke_test.lua .
lua5.1 Tools/full_load_smoke_test.lua .
```

## Pull requests

Describe:

1. the problem being fixed;
2. affected modules;
3. migration or network impact;
4. tests added or updated;
5. live OctoWoW checks still required.

Do not include personal SavedVariables, account data, guild exports, or `WTF` files.
