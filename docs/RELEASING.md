# Releasing Edward

## Cutting a release

1. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `Edward.xcodeproj/project.pbxproj`.
2. Run `./scripts/release.sh` — archives with Developer ID, deep re-signs Sparkle's
   nested helpers, notarizes (waits for Apple), staples, EdDSA-signs the zip,
   regenerates `appcast.xml`, and stages everything into `site/public/`.
3. Point `/download` at the new zip in `site/firebase.json`.
4. Deploy: `(cd site && firebase deploy --only hosting:theedward --project jasonsmithio)`
5. Verify externally (not just locally — the edge caches):
   ```bash
   curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' "https://theedward.app/download?cb=$(date +%s)"
   ```
6. Tag it: `git tag -a vX.Y.Z <sha> -m "..." && git push origin vX.Y.Z`

## Retention — do not delete the previous release

Keep at least the **two most recent** zips in `site/public/releases/`. They are the
only artifacts that exist: `release.sh` wipes `build/release/` on every run, and
`site/public/releases/` is gitignored, so a deleted zip is gone for good. Losing
them costs you the ability to repoint `/download` at a known-good build instantly.

## Rollback — read this before you need it

> **Sparkle only ever offers *newer* versions.** Pointing `appcast.xml` back at an
> older release does **not** downgrade anyone who already updated. It only changes
> what *new* downloaders get.

So there are two different situations:

### Stop the bleeding (new downloaders only)

Fast, partial. Repoint `/download` in `site/firebase.json` and regenerate the
appcast for the older hosted zip, then deploy. Anyone already updated stays put.

### Actually revert installed users

The only mechanism is **shipping a higher version that contains the reverted code**:

```bash
git revert -m 1 <bad-merge-sha>        # or git checkout <good-tag> -- <paths>
# bump MARKETING_VERSION *up* (e.g. 1.1.0 bad -> 1.1.1 containing 1.0.1's code)
./scripts/release.sh
# repoint /download, deploy, verify
```

Users on the bad version then see 1.1.1 as an update and move forward onto the
reverted code. Never reuse or decrement a version number to do this.

## Release history

| Version | Tag | Notes |
|---|---|---|
| 1.0.0 | `v1.0.0` | First notarized release, Sparkle auto-updates |
| 1.0.1 | `v1.0.1` | Sparkle 2.9.5 — GHSA-g3hp-f6mg-559v, GHSA-hg88-v3cw-3qrh |
| 1.1.0 | `v1.1.0` | macOS 27 support (hiding + Layout restored) |

## Gotchas learned the hard way

- **Zip packaging.** `release.sh` zips with `ditto --norsrc --noextattr`. A plain
  `ditto -c -k` encodes the sticky `com.apple.provenance` xattr as `._*` AppleDouble
  entries, which some extractors write into `Sparkle.framework/`'s root — Gatekeeper
  then rejects the app with *"unsealed contents present in the root directory of an
  embedded framework."* The script asserts 0 AppleDouble entries and aborts if any
  appear; don't remove that guard.
- **Sparkle's nested helpers** (`Downloader.xpc`, `Installer.xpc`, `Autoupdate`,
  `Updater.app`) ship with upstream signatures and must be re-signed deepest-first
  or notarization returns `Invalid`.
- **Dependency bumps from upstream PRs** can silently downgrade Sparkle. Always check
  `Package.resolved` after resolving — Edward must stay at **2.9.5 or newer**.
