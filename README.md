# Startup manual

## First step before running recrank: Install home manager

```
$ sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz home-manager
$ sudo nix-channel --update
```

(updated to the 24.05 version on 2024-07-10)


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

