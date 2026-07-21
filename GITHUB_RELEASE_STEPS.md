# GitHub publication steps for v1.7.2

## 1. Preserve the old repository state

Before replacing `main`, create a branch or tag from the current legacy commit:

- branch: `archive/legacy-1.5.7`
- optional tag: `v1.5.7-legacy`

## 2. Upload this prepared repository tree

Use a new branch:

- `release/1.7.2`

Replace the repository contents with this package. Do not upload `node_modules`, local ZIP files, SavedVariables, or `WTF` data.

## 3. Open a pull request

Title:

`Release OrderOfTheLionGM 1.7.2`

Suggested body:

- replaces the legacy 1.5.7 tree with the modular 1.7.2 source;
- adds MIT licensing, current README, changelog, contributor guidance, and security notes;
- adds validation and tagged-release GitHub Actions;
- preserves schema 14 and protocol 3;
- includes the stable TurtleRP transport fix and announcement read receipts.

## 4. Wait for CI

The `Validate addon` workflow must pass all four stages:

- static validation;
- Lua parsing;
- duplicate-definition analysis;
- deterministic runtime scenarios.

## 5. Merge into main

Prefer a squash merge titled:

`Release OrderOfTheLionGM 1.7.2`

## 6. Create the release tag

Create and push:

`v1.7.2`

The release workflow will verify that the tag matches `## Version: 1.7.2`, run all tests, build the install ZIP, generate SHA-256, and create the GitHub Release.

## 7. Verify the published archive

The ZIP must contain this path at its root:

`OrderOfTheLionGM/OrderOfTheLionGM.toc`

Do not publish the source-package ZIP as the player installation download.
