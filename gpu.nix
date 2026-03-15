{ config, ... }:

{
  # ── GPU / NVIDIA (RTX 3050 Ti Mobile + Intel Iris Xe) ───────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  # Dell XPS 15 9520 workarounds for NVIDIA GPU initialization
  boot.kernelParams = [
    "ibt=off"                                    # Required for XPS 9520 + NVIDIA proprietary
    "acpi_rev_override=1"                        # Fixes VBIOS access on Dell Optimus laptops
    "pci=realloc"                                # Fix PCI BAR allocation
    "nvidia.NVreg_DynamicPowerManagement=0x00"   # Prevent GPU runtime D3 power-off
  ];

  # Disable PCI runtime PM for the discrete GPU — prevents D3cold at boot
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", ATTR{power/control}="on"
  '';

  hardware.nvidia = {
    modesetting.enable = true;

    # Proprietary module required — open module fails GSP firmware init on this laptop GPU
    open = false;

    nvidiaSettings = true;

    # 535.x is more mature for this hardware; 580.x fails VBIOS init on this Dell
    package = config.boot.kernelPackages.nvidiaPackages.legacy_535;

    powerManagement.enable = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId  = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
