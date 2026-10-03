# Releasing bitcalc

## One-time setup

1. **Create the signing key** (on your own machine):

   ```bash
   scripts/gen-signing-key.sh
   ```

   It writes the *public* key to `keys/` and prints the *private* key.
   Commit `keys/bitcalc-archive-keyring.gpg`, `keys/bitcalc-archive-keyring.asc` and `keys/FINGERPRINT`.
   Keep an offline backup of the private key: if you lose it, every user has to re-run the installer
   to trust a new key.

2. **Add repository secrets** (Settings -> Secrets and variables -> Actions):

   | Secret | Value |
   |--------|-------|
   | `APT_GPG_PRIVATE_KEY` | the armored private key block printed by the script |
   | `APT_GPG_PASSPHRASE` | the passphrase you chose (leave unset if you used none) |

3. **Enable Pages from Actions**: Settings -> Pages -> Build and deployment -> Source: *GitHub Actions*.

4. If you rename the repository or change the owner, nothing else needs editing: URLs are derived from
   `GITHUB_REPOSITORY` at publish time. The maintainer e-mail lives in `packaging/control.in`
   and `scripts/gen-signing-key.sh`.

## Cutting a release

```bash
git tag v1.0.0
git push origin v1.0.0
```

The `Release` workflow then runs, in order:

1. **ci** - shellcheck, tests, fuzz, builds the `.deb`, installs it in Ubuntu 22.04/24.04 and Debian 12 containers.
2. **release** - creates a GitHub Release with the `.deb` attached.
3. **publish-apt** - gathers *every* released `.deb`, builds the flat repo, signs `Release` (`InRelease` + `Release.gpg`),
   deploys to GitHub Pages. It refuses to run if the secret key does not match the committed fingerprint.
4. **verify** - in fresh containers, runs the public `curl ... | bash` installer, checks the installed version equals the tag,
   then runs the uninstaller.

Tags with a hyphen (`v1.1.0-rc1`) are marked as pre-releases on GitHub but are still published to the repo.

## Rotating the key

Generate a new key, replace the files in `keys/`, update both secrets and release again. Users re-run
the one-liner installer (it replaces the keyring) or `apt` will report a signature error until they do.

## Local checks

```bash
make lint test
make deb VERSION=1.0.0 && sudo apt install ./dist/bitcalc_1.0.0_all.deb
```
