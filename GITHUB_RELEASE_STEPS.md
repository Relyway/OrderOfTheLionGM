# GitHub update steps for OrderOfTheLionGM 1.7.6 R5 Hotfix 1

## Updating `main` through the GitHub website

1. Extract the prepared ZIP.
2. Open the included `OrderOfTheLionGM` folder.
3. Upload all files and folders from inside it to the repository root.
4. Commit directly to `main`.
5. Wait for the `Validate OrderOfTheLionGM` workflow to finish successfully.

The repository root must contain `OrderOfTheLionGM.toc`, `Assets/`, `Modules/`, `Tools/`, and `.github/` directly. Do not create an additional nested `OrderOfTheLionGM` directory in the repository.

No GitHub Release or tag is required for a normal update to `main`.

## Player installation ZIP

A player installation ZIP must contain:

`OrderOfTheLionGM/OrderOfTheLionGM.toc`

Do not include SavedVariables, account data, `WTF`, `node_modules`, or local development caches.
