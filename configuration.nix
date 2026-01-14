# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
      ../nix-work
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

  # Enable networking
  networking.networkmanager.enable = true;


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
  hardware.pulseaudio.enable = false;
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cbertrand = {
    isNormalUser = true;
    description = "cbertrand";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      firefox  # browser
      git  # source control
      tmux  # terminal multiplexer
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
      pinentry  # Required by gnupg
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
      # X configs (colors + URxvt conf)
      ".Xresources" = {
        source = ./sources/xresources;
      };
      # Scripts to make available
      ".local/bin" = {
        source = ./sources/scripts;
        recursive = true;
      };
      # Vim conf
      ".vimrc" = {
        source = ./sources/vimrc;
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
      # URxvt conf
      ".urxvt/ext/resize-font" = {
        source = ./sources/rxvt-resize-font;
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

  environment.systemPackages = with pkgs;
  let
    unstable = import <nixos-unstable> { config = { allowUnfree = true; };};
  in

   [
     python312  # So that I can have an interactive python
     uv  # python package manager
     (vim_configurable.override { python3 = pkgs.python312; })
     telepresence2  # Allow direct connection to cluster
     killall  # To clean up processes
     fzf  # Required for vim
     wget
     rxvt-unicode-unwrapped  # Terminal
     system-config-printer
     unstable.claude-code
     unstable.gemini-cli
     unstable.codex
     dmidecode
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
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
