# Startup manual

## First step before running recrank: Install home manager

```
$ sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
$ sudo nix-channel --update
```

## Flake 101

- `nix flake show` — show what this flake exposes (configs, packages, apps).
- `nix flake update` — refresh pinned inputs in `flake.lock`.
- `sudo nixos-rebuild switch --flake .#wiremind` — rebuild and activate the system from the flake.
- `nix flake check` — evaluate the flake for errors and basic checks.


## Firefox config
Install following extensions:
- bitwarden
- ghostery
- uBlock origin


## Reset SSH keys on Github & other platforms

```
$ mkdir ~/.ssh
$ cd ~/.ssh
$ ssh-keygen -a 100 -t ed25519 -C "myemail@email.com"
$ chmod -R 700 ~/.ssh
```

### setexclude

Run `setexclude` in new git repo to configure the `.git/info/exclude` for custom files


### screenz

Run `screenz` to automatically set monitors


### startdm

Run `startdm` at startup to start the Display Manager


### switchkb

Run `switchkb` to switch between US and FR keyboard layout


## Upgrade packages

Go and see: https://superuser.com/questions/1604694/how-to-update-every-package-on-nixos


## Upgrade NixOS version

https://nixos.org/manual/nixos/stable/index.html#sec-upgrading
Update the channels using new version, always use sudo before nix-channel otherwise it won't do anything

## Checking configuration.nix before upgrade

Warning -> not that helpful actually
Run `sudo bash -x $(nix-build --no-out-link '<nixos/nixos>' -A system -I nixos-config=configuration.nix)/activate`
