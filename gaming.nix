{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;

    # LC_NUMERIC=C for Steam and everything it launches.
    #
    # configuration.nix sets i18n.extraLocaleSettings.LC_NUMERIC = "fr_FR.UTF-8",
    # which makes the decimal separator a comma. Windows games running under
    # Wine that parse floats out of their own config with locale-sensitive
    # strtod/atof then crash on startup. Baldur's Gate 3 died exactly one second
    # in, identically on both its Vulkan and DX11 renderers, until LC_ALL=C was
    # passed as a launch option — the renderer was never the variable, the
    # decimal separator was.
    #
    # Scoped to LC_NUMERIC rather than LC_ALL so French time, currency and paper
    # formats survive inside games; and set here rather than per-game because
    # every Windows title is exposed to the same trap.
    #
    # The module's `apply` merges this as `// (prev.extraEnv or { })`, so it wins
    # over the module's own entries and does not disturb the sibling
    # STEAM_EXTRA_COMPAT_TOOLS_PATHS that delivers proton-ge-bin.
    package = pkgs.steam.override {
      extraEnv.LC_NUMERIC = "C";
    };
  };

  # RADV (Mesa) is the default and the one to keep — do NOT add amdvlk.
  #
  # This machine has no dGPU: the display is driven by a Radeon 860M (RDNA 3.5,
  # 8 CUs) integrated in the Ryzen AI 7 PRO 450, sharing memory bandwidth with
  # all 16 CPU threads. amdvlk is behind RADV everywhere and further behind on
  # RDNA 3.5 APUs.
  #
  # Strictly redundant — programs.steam sets both of these unconditionally — but
  # kept explicit so this module still stands up if Steam is ever removed.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # capSysNice is NOT implied by `enable`: the module defaults it to false, and
  # only when it is true does it build security.wrappers.gamescope (at which
  # point the unwrapped binary is dropped from systemPackages — it lives in
  # /run/wrappers/bin instead). Without the capability gamescope cannot renice
  # itself and --rt does nothing.
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.gamemode = {
    enable = true;

    # enableRenice defaults to true, which is what gets gamemoded the
    # cap_sys_nice it needs for general.renice.
    #
    # The GPU half is opt-in, and it is where an 8-CU APU actually gains: the
    # DPM governor otherwise sits at "auto" and clocks conservatively under
    # sustained load. Upstream's warning applies to GPU tuning in general —
    # "high" only pins power_dpm_force_performance_level to the top DPM state,
    # which an APU's shared power budget already bounds.
    #
    # gpu_device is the DRM card index, NOT a PCI id: gpuclockctl builds
    # /sys/class/drm/card<N>/device/… from it. The default of 0 would be wrong
    # here — this machine exposes only card1, there is no card0, so 0 would
    # silently stat a nonexistent path and skip the optimisation entirely.
    # Recheck `ls /sys/class/drm` if the index ever moves; the failure mode is
    # benign (gamemoded logs and carries on) but also silent.
    settings = {
      general.renice = 10;
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 1;
        amd_performance_level = "high";
      };
    };
  };

  # programs.gamemode creates the `gamemode` group but puts nobody in it, and
  # gamemode's polkit rule gates the cpugovctl/gpuclockctl helpers on nothing
  # but membership of that group. Without this line `gamemoded -t` fails both
  # "CPU governor setting" and "GPU Optimisations" (pkcheck: "Not authorized")
  # while renice/ioprio still pass — gamemoded holds cap_sys_nice directly, so
  # the failures are confined to the two pkexec helpers, and everything in
  # settings.gpu above is silently inert. Nothing warns you about this.
  #
  # extraGroups is a list option, so this merges with the definition in
  # configuration.nix rather than replacing it.
  users.users.cbertrand.extraGroups = [ "gamemode" ];

  # Bluetooth is deliberately left off. The hardware is there (hci0) and nothing
  # else in this config brings the stack up, so wireless controllers cannot pair
  # — that is the intended trade: bluez is a large attack surface to run
  # permanently for a feature that is not used. Wired controllers are unaffected
  # (in-kernel xpad driver + the udev rules programs.steam already pulls in via
  # hardware.steam-hardware). xpadneo is likewise omitted: it is an out-of-tree
  # module and would be one more thing to break on a linuxPackages_latest bump.

  environment.systemPackages = with pkgs; [
    # The 32-bit Vulkan layer is already included: lowerBitnessSupport defaults
    # to true on x86_64 and the derivation symlinks MangoHud.x86.json.
    mangohud
    protonup-qt

    # Diagnostics — without these there is no way to confirm RADV is the driver
    # actually in use after a rebuild.
    vulkan-tools # vulkaninfo --summary
    radeontop # iGPU load (more useful here than on a dGPU)
    mesa-demos # glxinfo
  ];

  # boot.kernelPackages is deliberately NOT set here. configuration.nix already
  # pins linuxPackages_latest, with the CVE-2026-31431 rationale next to it, and
  # the option's type is types.raw — whose merge function throws on a second
  # definition even when both values are identical. Setting it here would be an
  # evaluation error, not a silent override.
}
