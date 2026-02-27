# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, pkgs-unstable, llmPkgs, ... }:

let
  zellij-autolock = pkgs.fetchurl {
    url = "https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm";
    sha256 = "194fgd421w2j77jbpnq994y2ma03qzdlz932cxfhfznrpw3mdjb9";
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Work-specific module is injected via flake input (nix-work).
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };


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
    dnssec = "allow-downgrade";
    fallbackDns = [ "192.168.1.1" ];  # demote router to fallback
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
    # Load nvidia driver for Xorg and Wayland
    # videoDrivers = ["nvidia"];

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
      tmux  # terminal multiplexer
      zellij  # terminal multiplexer (tmux replacement)
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
      texlive.combined.scheme-full  # LaTeX compiler + libraries
      kdePackages.kcachegrind
      graphviz  # Used in kcachegrind
      vlc  # Video player
      nix-tree  # Packages vizualizer
      infisical  # Secret management
      glab  # Gitlab CLI
      jq  # json reading for shell scripts
      libnotify  # Desktop notifications (notify-send) for hooks
    ];
  };

  home-manager.users.cbertrand = { pkgs, ... }: {
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
      ".aliases" = {
        source = ./sources/aliases.sh;
      };
      # Tmux conf
      ".tmux.conf" = {
        source = ./sources/tmux.conf;
      };
      # Zellij config
      ".config/zellij/config.kdl" = {
        source = ./sources/zellij.kdl;
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
      # Claude Code user settings (hooks, preferences)
      ".claude/settings.json" = {
        source = ./sources/claude-settings.json;
      };
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # nixpkgs.config.cudaSupport = true;

  # Allowed unsecure packages
  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-14.21.3"  # Still in use in old projects
    "nodejs_14"
  ];

  environment.systemPackages = with pkgs; [
    python313
    uv  # python package manager
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
    git-prole  # Git worktree management
    rofi  # Application launcher (dmenu replacement)
    system-config-printer
    # LLM coding agents (from numtide/llm-agents.nix, auto-updated daily)
    llmPkgs.claude-code
    llmPkgs.gemini-cli
    llmPkgs.codex
    dmidecode
    gcc
    gnumake
    nodejs_22
    # LSP servers for Neovim
    pyright  # Python LSP
    pkgs-unstable.rust-analyzer  # Rust LSP
    nodePackages.typescript-language-server  # TypeScript LSP
    lua-language-server  # Lua LSP
    # Formatters/linters (shared with Vim ALE)
    ruff  # Python linter/formatter
    nodePackages.prettier  # JS/TS formatter
    nodePackages.eslint  # JS/TS linter
  ];

  environment.variables.EDITOR = "vim";

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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
