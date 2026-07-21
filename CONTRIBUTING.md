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

```bash
npm ci
npm run validate
npm run parse
npm run ast
npm test
```

## Pull requests

Describe:

1. the problem being fixed;
2. affected modules;
3. migration or network impact;
4. tests added or updated;
5. live OctoWoW checks still required.

Do not include personal SavedVariables, account data, guild exports, or `WTF` files.
