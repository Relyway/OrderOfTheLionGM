# GitHub web release steps — OrderOfTheLionGM 1.8.0

1. Open `Relyway/OrderOfTheLionGM` and stay on branch `main`.
2. Extract the GitHub publish-ready ZIP locally. Do **not** upload the ZIP itself as repository source.
3. Use **Add file → Upload files** and upload the extracted contents to the repository root.
4. Confirm `OrderOfTheLionGM.toc` is at the repository root and contains `## Version: 1.8.0`.
5. Commit directly to `main` with message `Release OrderOfTheLionGM 1.8.0`.
6. Open **Actions** and wait for `Validate OrderOfTheLionGM 1.8.0` to become green.
7. Open **Releases → Draft a new release**.
8. Create tag `v1.8.0` from `main`.
9. Release title: `OrderOfTheLionGM 1.8.0`.
10. Attach the install archive `OrderOfTheLionGM-1.8.0.zip` and optionally `OrderOfTheLionGM-1.8.0-SHA256.txt`.
11. Do not mark it as a pre-release. Mark it as the latest release and publish.

For OctoLauncher git updates, the important part is the updated `main` branch, not the GitHub Release attachment. The launcher pulls the git repository and then reads `OrderOfTheLionGM.toc` from the addon folder.
