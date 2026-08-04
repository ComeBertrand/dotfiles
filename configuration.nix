# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, lib, pkgs, inputs, pkgs-unstable, llmPkgs, tamPkg, ... }:

let
  zellij-autolock = pkgs.fetchurl {
    url = "https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm";
    sha256 = "194fgd421w2j77jbpnq994y2ma03qzdlz932cxfhfznrpw3mdjb9";
  };

  # ── Syncthing ───────────────────────────────────────────────────────────
  # Device IDs are public identifiers, not secrets, so they belong in this repo.
  #
  # THIS machine (wiremind) — give this to the other machine when pairing:
  #   CYDUPOM-WGPKWZJ-B3A4ZU3-VNAUCE6-DAECQFY-GGF3WE3-T7YHW3H-7G6CTAJ
  #
  # Recorded here for reference only. Do NOT add it to syncthingPeers below:
  # that attrset declares *remote* peers, and syncthing already knows itself as
  # the local device — listing it would duplicate the local device entry.
  #
  # Re-read it at any time with (syncthing 2.x needs --home, or BOTH --config
  # and --data; `device-id` is a subcommand, not a flag):
  #   syncthing --home=/home/cbertrand/.config/syncthing device-id
  #
  # To pair a new machine:
  #   1. Get that machine's ID the same way (or web UI → Actions → Show ID).
  #   2. Add it to syncthingPeers below, uncommented, then run ./recrank.sh
  #   3. Do the mirror-image setup there, using this machine's ID above.
  #   4. Folder IDs ("documents"/"workspace") must match on both ends;
  #      the local paths may differ.
  #
  # syncthingPeers is the ONLY place to edit when adding a machine — the
  # devices attrset and both folders' share lists are derived from it.
  # While it is empty the folders are declared but shared with nobody.
  # NOTE: overrideDevices = true below means pairing via the web UI gets
  # reverted on the next rebuild. Pairing happens here, not in the GUI.
  syncthingPeers = {
    old-laptop = "CYDUPOM-WGPKWZJ-B3A4ZU3-VNAUCE6-DAECQFY-GGF3WE3-T7YHW3H-7G6CTAJ";
  };
  syncthingPeerNames = builtins.attrNames syncthingPeers;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # ./gpu.nix  # Disabled — GPU hardware defect (VBIOS unreadable, RmInitAdapter fails)
      # Work-specific module is injected via flake input (nix-work).
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  # Pinned for CVE-2026-31431 (Copy Fail) — needs kernel ≥ 6.18.22.
  # 6.18.29 had an iwlwifi/iwlmvm regression on AX211 (driver loaded ucode
  # but stalled before PNVM/netdev creation), so we use the 7.0 line instead.
  # Unpin once the 6.12 LTS line picks up the backport.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Swap: nvme0n1p3, encrypted with a fresh random key on every boot.
  #
  # hardware-configuration.nix declares this partition as
  # /dev/mapper/luks-df3f27e6-… but nixos-generate-config never emitted the
  # matching boot.initrd.luks.devices entry, so nothing ever unlocked it. That
  # mapper node never appeared and systemd waited out its full 90s
  # DefaultDeviceTimeout — on every boot AND every nixos-rebuild switch — while
  # leaving the machine with no swap at all.
  #
  # mkForce, not a plain definition: swapDevices is a list option, so a second
  # definition would append and leave the broken entry in place.
  #
  # by-partuuid is required here, not by-uuid: randomEncryption overwrites the
  # partition's LUKS header (and thus its UUID) on every boot, so a by-uuid link
  # would vanish. This is upstream's own advice in nixos/modules/config/swap.nix.
  #
  # Consequence of the random key: hibernation is impossible, by design. Fine at
  # 8.8G of swap against 58 GiB of RAM, where hibernation was never realistic.
  swapDevices = lib.mkForce [
    {
      device = "/dev/disk/by-partuuid/66078ec4-f6d3-4069-a747-c107495f9f0f";
      randomEncryption.enable = true;
    }
  ];


  networking.hostName = "wiremind"; # Define your hostname.
  # This can be setup to add lines in /etc/hosts
  # networking.extraHosts =
  #   ''
  #     XX.XX.XX.XX my-url
  #   '';

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";



  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      FallbackDNS = [ "192.168.1.1" ];  # demote router to fallback
    };
  };# Tell NetworkManager to prepend these as per-link DNS

  # Enable networking
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
    insertNameservers = [ "8.8.8.8" "1.1.1.1" ];
  };


  services.displayManager = {
    # Enable GNOME
    # gdm.enable = true;

    # Enable i3
    defaultSession = "none+i3";
  };
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "";

    # Only for i3, force manual launch of display manager
    autorun = false;

    desktopManager = {
      # Enable GNOME
      # gnome.enable = true;

      # Enable i3
      xterm.enable = false;
    };


    # i3 config
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu # application launcher
        i3status # status bar
        i3lock # screen locker
        xss-lock # lock on suspend + on X screensaver event
        xset # sets the X screensaver idle timeout
      ];
    };
  };


  # Enable CUPS to print documents.
  services.printing.enable = false;
  services.avahi = {
    enable = false;
    nssmdns4 = false;
    openFirewall = false;
  };


  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable docker
  virtualisation.docker.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.cbertrand = {
    isNormalUser = true;
    description = "cbertrand";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      firefox  # browser
      git  # source control
      pkgs-unstable.zellij  # terminal multiplexer (unstable: 25.11 rustc too old)
      ranger  # file manager
      docker-compose  # enable composing of containers
      slack  # communication platform
      direnv  # Custom virtualenvs in folders
      nix-direnv  # Use nix-shell with direnv
      universal-ctags  # Used for tag generation by vim
      dunst  # Notification-daemon
      htop  # Process manager
      kubectl  # Manage kubernetes cluster CLI
      kubernetes-helm  # Kubernetes package manager
      k9s  # Kubernetes cluster management
      # The kubectl plugins mayo needs (kubelogin, kubectx/kubens,
      # kubectl_view_secret) come from ~/nix-work, see wmdotfiles.
      xsel  # Allows clipboard copy/paste
      flameshot  # Screenshot tool
      pulseaudio  # Sound control
      pavucontrol  # Sound control
      google-chrome  # Secondary browser
      unzip  # Unzip files
      gnupg  # Handle PGP
      visidata  # Useful for data analysis
      postman  # API testing
      gthumb  # Image manipulation
      peek  # Create GIF from screen
      scc  # Project eval
      openssl  # Used for certificate & stuff
      awscli2  # AWS client
      filezilla  # SFTP client
      kdePackages.kcachegrind
      graphviz  # Used in kcachegrind
      vlc  # Video player
      nix-tree  # Packages vizualizer
      infisical  # Secret management
      glab  # Gitlab CLI
      jq  # json reading for shell scripts
      libnotify  # Desktop notifications (notify-send) for hooks
      glow  # Markdown renderer for terminal
      tamPkg  # Terminal agent multiplexer
    ];
  };

  home-manager.users.cbertrand = { pkgs, ... }: {
    imports = [ ./sources/zen.nix ];
    home.stateVersion = "23.05";
    home.file = {
      # Git config (email, ...)
      ".config/git/config" = {
        source = ./sources/gitconfig.conf;
      };
      # i3 configuration
      ".config/i3/config" = {
        source = ./sources/i3config.conf;
      };
      # Direnv functions (auto venv for python, ...)
      ".config/direnv/direnvrc" = {
        source = ./sources/direnvrc.sh;
      };
      # Direnv config (auto-allow Workspace directories)
      ".config/direnv/direnv.toml" = {
        source = ./sources/direnv.toml;
      };
      # Custom nixpkgs config
      ".config/nixpkgs/config.nix" = {
        source = ./sources/config.nix;
      };
      # Custom gpg-agent conf
      ".gnupg/gpg-agent.conf" = {
        source = ./sources/gpg-agent.conf;
      };
      # Scripts to make available
      ".local/bin" = {
        source = ./sources/scripts;
        recursive = true;
      };
      # Vim conf (kept as fallback)
      ".vimrc" = {
        source = ./sources/vimrc;
      };
      # Neovim configuration
      ".config/nvim" = {
        source = ./sources/nvim;
        recursive = true;
      };
      # Yazi configuration
      ".config/yazi/keymap.toml" = {
        source = ./sources/yazi_keymap.toml;
      };
      ".config/yazi/yazi.toml" = {
        source = ./sources/yazi.toml;
      };
      # Bash configuration files
      ".bashrc" = {
        source = ./sources/bashrc.sh;
      };
      ".bash_profile" = {
        source = ./sources/bash_profile.sh;
      };
      ".bash_prompt" = {
        source = ./sources/bash_prompt.sh;
      };
      ".path" = {
        source = ./sources/path.sh;
      };
      ".exports" = {
        source = ./sources/exports.sh;
      };
      ".aliases" = {
        source = ./sources/aliases.sh;
      };
      # Zellij config
      ".config/zellij/config.kdl" = {
        source = ./sources/zellij.kdl;
      };
      # Zellij default layout (compact-bar with mode indicator)
      ".config/zellij/layouts/default.kdl" = {
        source = ./sources/zellij-layout.kdl;
      };
      # Zellij dev layout (nvim + two terminals)
      ".config/zellij/layouts/dev.kdl" = {
        source = ./sources/zellij-layout-dev.kdl;
      };
      # Zellij autolock plugin (auto-lock when nvim/vim/git/fzf run)
      ".config/zellij/plugins/zellij-autolock.wasm" = {
        source = zellij-autolock;
      };
      # Kitty terminal config
      ".config/kitty/kitty.conf" = {
        source = ./sources/kitty.conf;
      };
      # Rofi launcher config
      ".config/rofi/config.rasi" = {
        source = ./sources/rofi-config.rasi;
      };
      # Tam agent multiplexer config
      ".config/tam/config.toml" = {
        source = ./sources/tam-config.toml;
      };
      # Claude Code user settings (hooks, preferences)
      ".claude/settings.json" = {
        source = ./sources/claude-settings.json;
      };
    };
    # Startup housekeeping service
    systemd.user.services.morning = {
      Unit.Description = "Morning housekeeping";
      Service = {
        Type = "oneshot";
        ExecStart = "%h/.local/bin/morning";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Allowed unsecure packages
  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-14.21.3"  # Still in use in old projects
    "nodejs_14"
  ];

  environment.systemPackages = with pkgs; [
    python313
    pkgs-unstable.uv  # python package manager
    # The PostgreSQL client (`psql`, `pg_config`) comes from ~/nix-work, see
    # wmdotfiles — it is only needed for the work layer's mayo and ksql.
    (vim-full.override { python3 = pkgs.python313; })  # Keep vim as fallback
    neovim  # Modern editor with native LSP support
    telepresence2  # Allow direct connection to cluster
    killall  # To clean up processes
    fzf  # Required for vim and nvim
    ripgrep  # Required for telescope.nvim live grep
    fd  # Fast file finder for telescope.nvim
    pkgs-unstable.yazi  # Terminal file manager for yazi.nvim
    wget
    kitty  # GPU-accelerated terminal
    jujutsu  # Git-compatible VCS frontend
    rofi  # Application launcher (dmenu replacement)
    gh  # GitHub CLI
    system-config-printer
    # LLM coding agents (from numtide/llm-agents.nix, auto-updated daily)
    llmPkgs.claude-code
    pkgs-unstable.codex
    # CLI for fly.io
    pkgs-unstable.flyctl
    dmidecode
    gcc
    gnumake
    nodejs_22
    # LSP servers for Neovim
    pyright  # Python LSP
    pkgs-unstable.rust-analyzer  # Rust LSP
    typescript-language-server  # TypeScript LSP
    lua-language-server  # Lua LSP
    # Formatters/linters (shared with Vim ALE)
    ruff  # Python linter/formatter
    prettier  # JS/TS formatter
    eslint  # JS/TS linter
  ];

  environment.variables.EDITOR = "nvim";

  # Terminal fonts, chose the one you prefer
  fonts.packages = with pkgs; [
    hermit
    source-code-pro
    terminus_font
  ];

  # Enable nix-ld with recommended defaults (allows usage of pre-build executables like ruff)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      expat
      libuuid
      icu
      zstd
      xz
    ];
  };

  # `<nixos-unstable>` for the non-flake shell.nix files nixinit generates
  # (Rust projects pull cargo/rustc/clippy from unstable). There is no
  # nix-channel on this machine, so point the angle-bracket lookup at the
  # flake's own nixpkgs-unstable input: same tree, pinned by flake.lock.
  # NixOS' own entries are `lib.mkDefault`, so any definition here replaces the
  # whole list: `nixpkgs=flake:nixpkgs` and the channels dir must be restated,
  # or `<nixpkgs>` breaks in every shell.nix.
  #
  # `flake:nixos-unstable` (indirection through nix.registry below), not a raw
  # `${inputs.nixpkgs-unstable}` store path: the path changes on every
  # `nix flake update`, so a shell that outlives a rebuild would keep pointing
  # at the old one and break once cleanup.sh garbage-collects it. The flakeref
  # is resolved at eval time against /etc/nix/registry.json, which every
  # rebuild refreshes.
  nix.nixPath = [
    "nixpkgs=flake:nixpkgs"
    "nixos-unstable=flake:nixos-unstable"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];
  nix.registry.nixos-unstable.flake = inputs.nixpkgs-unstable;

  # Numtide binary cache for llm-agents (pre-built packages)
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # File sync between machines. Peers are declared in `syncthingPeers` at the
  # top of this file; everything else is derived from it.
  services.syncthing = {
    enable = true;
    user = "cbertrand";
    group = "users";  # match the rest of $HOME, so synced files aren't cbertrand:syncthing
    dataDir = "/home/cbertrand";  # service working dir + base for configDir
    configDir = "/home/cbertrand/.config/syncthing";  # device ID & keys live here

    # Opens 22000/tcp+udp (transfers) and 21027/udp (LAN discovery).
    openDefaultPorts = true;
    # Web UI stays on 127.0.0.1:8384 (module default) — never exposed to the LAN.

    # This repo is the source of truth: devices/folders added in the web UI are
    # deleted on rebuild. Both default to true; stated explicitly as a reminder.
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      devices = builtins.mapAttrs (_name: id: { inherit id; }) syncthingPeers;

      # Keyed by short name → that name becomes the folder ID, which must match
      # on every peer. Paths are set explicitly so they can differ per machine.
      folders = {
        documents = {
          path = "/home/cbertrand/Documents";
          devices = syncthingPeerNames;
          # Deletions land in .stversions instead of being propagated away.
          versioning = {
            type = "trashcan";
            params.cleanoutDays = "30";
          };
        };

        workspace = {
          path = "/home/cbertrand/Workspace";
          devices = syncthingPeerNames;
          versioning = {
            type = "trashcan";
            params.cleanoutDays = "30";
          };
          # Without these, syncthing would ship every venv, node_modules and
          # target/ dir across the wire. Patterns without a slash match at any
          # depth. Applied via syncthing's REST API on rebuild.
          ignorePatterns = [
            "// Build & dependency dirs"
            ".venv"
            "venv"
            "node_modules"
            "target"
            "dist"
            "build"
            ".next"
            "// Nix build outputs"
            "result"
            "result-*"
            "// Tool caches"
            ".direnv"
            "__pycache__"
            "*.pyc"
            ".mypy_cache"
            ".pytest_cache"
            ".ruff_cache"
            ".cache"
            "// Editor/OS noise"
            "*.swp"
            ".DS_Store"
          ];
        };
      };

      options = {
        urAccepted = -1;  # decline anonymous usage reporting
        relaysEnabled = true;  # allow sync when the peers aren't on the same LAN
      };
    };
  };

  networking.firewall = {
    enable = true;
    # Syncthing's ports are added by services.syncthing.openDefaultPorts.
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
