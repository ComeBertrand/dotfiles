# dotfiles — NixOS install manual

Declarative NixOS configuration for `wiremind`: i3, Neovim, Kubernetes tooling, and a
Python/Rust/TypeScript dev environment. Everything is pinned by `flake.lock`, so a
rebuild on new hardware reproduces the same system.

- **Host:** `wiremind` · **User:** `cbertrand` · **NixOS:** 26.05
- Day-to-day change recipes live in [CLAUDE.md](CLAUDE.md).

> **Two audiences, one guide.** Steps 1–2 are only for a *brand-new machine or a
> reinstall*. If you already have a working system and just want to apply changes, skip
> to [Everyday use](#everyday-use).

---

## What you cannot get from this repo

Nix reproduces the system, not your secrets or your accounts. Budget for these — they
are all covered in [Step 5](#step-5--manual-setup-nix-cannot-do-this):

| Not in the repo | Why |
|---|---|
| User password | Set with `passwd`; no `hashedPassword` is declared |
| SSH / GPG keys | Private keys — never commit these |
| `~/.kube/config`, cloud credentials | Per-machine secrets |
| Browser / Slack / Postman logins | Account state |
| Syncthing device IDs | Generated per machine on first run (public, so they *do* get committed once known) |

---

## Step 1 — Install base NixOS (new machine only)

1. Flash the **NixOS 26.05 graphical ISO** and boot it.

2. Run the graphical installer (Calamares) and **check "Encrypt system"**. The committed
   `hardware-configuration.nix` describes exactly that layout: a LUKS-encrypted `ext4`
   root, a `vfat` `/boot` ESP, and a swap partition. Matching it now saves work later.

3. Create the user **`cbertrand`** — the whole config is written around that username.

4. Reboot into the fresh system. Don't customise anything yet; the next steps replace
   `/etc/nixos` wholesale.

---

## Step 2 — Bootstrap this repo

Nix flakes only read **git-tracked** files, so you must *clone* the repo — copying the
directory or downloading a zip will silently drop files during evaluation.

```bash
# Clone over HTTPS: you have no SSH key yet (that comes in Step 5).
nix-shell -p git --run 'git clone https://github.com/ComeBertrand/dotfiles.git ~/dotfiles'
cd ~/dotfiles
```

**Keep the repo at `~/dotfiles`.** `recrank.sh` and `upgrade.sh` look for the optional
work module at `../nix-work`, so the path is load-bearing.

### Regenerate the hardware config — do not skip this

`hardware-configuration.nix` is machine-specific: it pins filesystem **UUIDs** and the
**LUKS device name** of the machine it was generated on. Reusing this machine's copy on
different hardware produces a system that will not boot.

```bash
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
git add hardware-configuration.nix   # flakes ignore untracked files
```

Then check two things in the regenerated file:

- A `boot.initrd.luks.devices.* ` line exists if you encrypted the disk. If it's missing,
  the system won't unlock at boot.
- If you did **not** encrypt, also remove the `boot.initrd.secrets."/crypto_keyfile.bin"`
  entry near the top of `configuration.nix`.

### Set `stateVersion` — only on a genuinely new install

`configuration.nix` ends with `system.stateVersion = "23.05";`. This is not a version to
keep current — it records the release a machine was *first* installed with, and changing
it on a live system can migrate stateful services badly.

- **Restoring/reinstalling this same machine:** leave it at `23.05`.
- **A brand-new machine:** set it to the release you just installed from (`26.05`).

---

## Step 3 — First rebuild

```bash
cd ~/dotfiles
./recrank.sh
```

This runs `sudo nixos-rebuild switch --flake .#wiremind`, adding
`--override-input nix-work path:../nix-work` when that directory exists.

Expect the first run to take a while — it builds the full closure. Home Manager is a
**flake input** (`home-manager.url = ".../release-26.05"`), so there is *nothing* to add
with `nix-channel`; any older instructions to do so are obsolete.

If it fails, jump to [Troubleshooting](#troubleshooting).

---

## Step 4 — Start the graphical session

X11 does **not** autostart (`services.xserver.autorun = false`). After logging in on the
TTY:

```bash
startdm
```

Then set up monitors:

```bash
screenz
```

`startdm` lives in `~/.local/bin`, which is on your PATH from `.path`. Note that **i3
keybindings do not inherit that PATH** — bindings in `sources/i3config.conf` need full
paths like `~/.local/bin/screenz`.

---

## Step 5 — Manual setup (Nix cannot do this)

### 5.1 User password

```bash
passwd            # no hashedPassword is declared, so this must be set by hand
```

### 5.2 SSH key, then switch the remote to SSH

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -a 100 -t ed25519 -C "come.bertrand@protonmail.com"
cat ~/.ssh/id_ed25519.pub      # add to GitHub / GitLab
```

Once the key is registered, move this clone off HTTPS:

```bash
cd ~/dotfiles
git remote set-url origin git@github.com:ComeBertrand/dotfiles.git
ssh -T git@github.com          # verify
```

### 5.3 GPG

`~/.gnupg/gpg-agent.conf` is managed by Home Manager, but keys are not. Import them from
your backup:

```bash
gpg --import <secret-key-backup>.asc
```

### 5.4 Syncthing — the fastest way to move your files over

Syncthing is enabled and pre-declares two folders, which makes it the intended path for
pulling `~/Documents` and `~/Workspace` onto a new machine.

Pairing is **declarative**: `overrideDevices = true`, so devices added through the web UI
are wiped on the next rebuild. Add peers to the `syncthingPeers` attrset at the top of
`configuration.nix` — that is the single place to edit, and both folders' share lists
derive from it.

```bash
# 1. On EACH machine, print its device ID (public — safe to commit).
#    Syncthing 2.x needs --home (or BOTH --config and --data), and device-id
#    is a subcommand, not a flag:
syncthing --home=$HOME/.config/syncthing device-id

# 2. Add the *other* machine's ID to syncthingPeers in configuration.nix:
#      syncthingPeers = {
#        laptop = "AAAAAAA-BBBBBBB-...";
#      };
# 3. Apply on both ends:
./recrank.sh
```

Folder IDs must match on both machines — they are **`documents`** and **`workspace`**.
The local paths may differ. The web UI is at <http://127.0.0.1:8384> (bound to localhost;
never exposed to the LAN).

Two things to expect on first sync:

- `~/Workspace` carries `ignorePatterns` for `.venv`, `node_modules`, `target`, `.direnv`
  and friends — this cuts it from ~103 G to ~4 G. Add any build dir you introduce later.
- Both folders use `trashcan` versioning (30 days), so a delete on one machine parks the
  file in `.stversions` on the other instead of propagating the deletion.

### 5.5 Browsers

**Zen** (the primary browser) is fully declarative via `sources/zen.nix` — uBlock Origin,
Bitwarden, ClearURLs, Proton Pass and Proton VPN install themselves. You only sign in.

Plain `firefox` is installed as an unconfigured package. If you use it, add extensions by
hand.

### 5.6 Work module (optional)

Work-specific config lives outside this repo. Clone it as a **sibling** and both scripts
pick it up automatically:

```bash
git clone <work-repo> ~/nix-work    # ../nix-work relative to ~/dotfiles
./recrank.sh
```

Without it, the in-repo `nix-work/default.nix` stub is used and does nothing.

### 5.7 Remaining logins

Sign in to Slack, Google Chrome, Postman, `infisical login`, `aws configure`, and drop
your `~/.kube/config` in place.

---

## Everyday use

```bash
./recrank.sh      # apply config changes (rebuild + switch)
./upgrade.sh      # nix flake update, then rebuild — bumps flake.lock
nix flake update  # update inputs only, no rebuild
./cleanup.sh      # garbage-collect generations older than 15 days
./cleanup-hard.sh # garbage-collect everything unreferenced
```

**Always commit `flake.lock`.** It is what makes these builds reproducible.

### Flake commands

| Command | Purpose |
|---|---|
| `nix flake show` | What this flake exposes |
| `nix flake check` | Evaluate for syntax/eval errors |
| `nix flake metadata` | Inspect pinned inputs |
| `sudo nixos-rebuild switch --flake .#wiremind` | Manual rebuild |

Verify a change builds **without** switching — useful before committing:

```bash
nix build .#nixosConfigurations.wiremind.config.system.build.toplevel --no-link
```

### Scripts

| Script | Purpose |
|---|---|
| `startdm` | Start X11/i3 — **required**, autorun is disabled |
| `screenz` | Configure monitors |
| `switchkb` | Toggle US/FR keyboard layout |
| `nixinit <python\|rust\|node>` | Scaffold `.envrc` + `shell.nix` + git excludes in a project |
| `dcs` | Docker Compose services helper (run inside a project with a `compose.yaml`) |
| `k9` | Pick a process with fzf and kill it |
| `dev-open` / `tam-open` | Launch a kitty + zellij dev session (`tam-open` picks the project via rofi) |

`morning` runs automatically as a systemd user service at login (purges dead zellij
sessions).

### NixOS version upgrade

Bump both inputs in `flake.nix` together — they must stay on the same release:

```nix
nixpkgs.url = "github:NixOS/nixpkgs/nixos-XX.XX";
home-manager.url = "github:nix-community/home-manager/release-XX.XX";
```

```bash
nix flake update
./recrank.sh
sudo reboot
```

Leave `system.stateVersion` alone. See the
[NixOS upgrade docs](https://nixos.org/manual/nixos/stable/index.html#sec-upgrading).

---

## Troubleshooting

**A new file is "missing" during rebuild.** Flakes only see git-tracked files:

```bash
git add <file> && ./recrank.sh
```

**Syntax or evaluation error.**

```bash
nix flake check
```

**The system boots to a broken state.** Pick a previous generation in the boot menu, or:

```bash
sudo nixos-rebuild switch --rollback --flake .#wiremind
```

**A bad `flake.lock` update.**

```bash
git checkout HEAD~1 -- flake.lock
./recrank.sh
```

**New machine won't boot after the first switch.** Almost always
`hardware-configuration.nix` — confirm you regenerated it, `git add`ed it, and that the
`boot.initrd.luks.devices` line matches your actual disk.

**Neovim / LSP problems.** `:Lazy restore`, `:checkhealth`, `:LspInfo`. Language servers
are installed from `configuration.nix`, not Mason.

**Don't run `git status -uall`** in large repos here — it can exhaust memory.
