{ inputs, pkgs, lib, config, ... }:

{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;

    # ─── Enforced enterprise policies (policies.json) ───
    policies = {
      DisableTelemetry         = true;
      DisableFirefoxStudies    = true;
      DisablePocket            = true;
      DisableFeedbackCommands  = true;
      DontCheckDefaultBrowser  = true;
      OfferToSaveLogins        = false;   # assuming password manager usage
      NoDefaultBookmarks       = true;
      DisableFirefoxAccounts   = false;   # keep Sync available; set true to kill it
      AutofillCreditCardEnabled = false;

      EnableTrackingProtection = {
        Value          = true;
        Locked         = true;
        Cryptomining   = true;
        Fingerprinting = true;
        EmailTracking  = true;
      };

      Cookies = {
        Behavior = "reject-tracker-and-partition-foreign";
      };

      DNSOverHTTPS = {
        Enabled     = true;
        ProviderURL = "https://dns.quad9.net/dns-query";
        Locked      = false;
      };

      FirefoxHome = {
        Search            = true;
        TopSites          = false;
        SponsoredTopSites = false;
        Highlights        = false;
        Pocket            = false;
        SponsoredPocket   = false;
        Snippets          = false;
      };

      UserMessaging = {
        WhatsNew                 = false;
        ExtensionRecommendations = false;
        FeatureRecommendations   = false;
        UrlbarInterventions      = false;
        SkipOnboarding           = true;
        MoreFromMozilla          = false;
      };

      Permissions = {
        Notifications = { BlockNewRequests = true; Locked = false; };
      };

      EncryptedMediaExtensions = { Enabled = true; Locked = false; };

      # Force-install extensions not packaged in rycee's NUR.
      # install_url pulls the AMO-latest XPI on first launch (not hash-pinned).
      ExtensionSettings = {
        "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
        };
        "vpn@proton.ch" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-vpn-firefox-extension/latest.xpi";
        };
      };
    };

    profiles."default" = {
      id = 0;  # must be 0 for the default profile

      # ─── about:config prefs (user.js) ───
      # These are NOT locked — user can change in UI, but they snap back on rebuild.
      settings = {
        # Belt-and-braces telemetry kill (policies cover most, these cover the rest)
        "toolkit.telemetry.enabled"                     = false;
        "toolkit.telemetry.unified"                     = false;
        "toolkit.telemetry.archive.enabled"             = false;
        "toolkit.telemetry.newProfilePing.enabled"      = false;
        "toolkit.telemetry.shutdownPingSender.enabled"  = false;
        "toolkit.telemetry.updatePing.enabled"          = false;
        "toolkit.telemetry.bhrPing.enabled"             = false;
        "toolkit.telemetry.firstShutdownPing.enabled"   = false;
        "toolkit.telemetry.coverage.opt-out"            = true;
        "toolkit.coverage.opt-out"                      = true;
        "toolkit.coverage.endpoint.base"                = "";
        "datareporting.healthreport.uploadEnabled"      = false;
        "datareporting.policy.dataSubmissionEnabled"    = false;
        "app.shield.optoutstudies.enabled"              = false;
        "app.normandy.enabled"                          = false;
        "app.normandy.api_url"                          = "";

        # Crash reports
        "breakpad.reportURL"                               = "";
        "browser.tabs.crashReporting.sendReport"           = false;
        "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;

        # Kill the "Zen sends keystrokes to Google" default
        "browser.search.suggest.enabled"              = false;
        "browser.urlbar.suggest.searches"             = false;
        "browser.urlbar.speculativeConnect.enabled"   = false;
        "browser.formfill.enable"                     = false;

        # Tracking protection (redundant with policy but harmless)
        "browser.contentblocking.category"                    = "strict";
        "privacy.trackingprotection.enabled"                  = true;
        "privacy.trackingprotection.socialtracking.enabled"   = true;
        "privacy.trackingprotection.cryptomining.enabled"     = true;
        "privacy.trackingprotection.fingerprinting.enabled"   = true;
        "privacy.trackingprotection.emailtracking.enabled"    = true;

        # Total Cookie Protection
        "network.cookie.cookieBehavior"    = 5;
        "privacy.partition.network_state"  = true;

        # Light fingerprinting protection. DO NOT enable
        # privacy.resistFingerprinting outside of Tor Browser — it makes you
        # *more* unique, not less.
        "privacy.fingerprintingProtection" = true;

        # HTTPS-only
        "dom.security.https_only_mode"              = true;
        "dom.security.https_only_mode_ever_enabled" = true;

        # Network chatter
        "browser.send_pings"          = false;
        "network.prefetch-next"       = false;
        "network.dns.disablePrefetch" = true;
        "network.predictor.enabled"   = false;

        # WebRTC LAN IP leak — strict mode (matches previous Firefox setup).
        # May break some video calls; loosen by removing no_host if needed.
        "media.peerconnection.ice.default_address_only"    = true;
        "media.peerconnection.ice.no_host"                 = true;
        "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;

        # Container tabs (Multi-Account Containers)
        "privacy.userContext.enabled"    = true;
        "privacy.userContext.ui.enabled" = true;

        # Activity Stream / newtab telemetry
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry"       = false;
        "browser.ping-centre.telemetry"                      = false;

        # Make force-installed extensions load on first run
        "extensions.autoDisableScopes" = 0;
      };

      # ─── Search engines ───
      search = {
        force = true;
        default = "ddg";
        engines = {
          "nixpkgs" = {
            name = "Nixpkgs";
            urls = [{ template = "https://search.nixos.org/packages?query={searchTerms}"; }];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };
          "nixos-options" = {
            name = "NixOS options";
            urls = [{ template = "https://search.nixos.org/options?query={searchTerms}"; }];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@no" ];
          };
          "noogle" = {
            name = "noogle";
            urls = [{ template = "https://noogle.dev/q?term={searchTerms}"; }];
            definedAliases = [ "@ng" ];
          };
          # Disable the usual chaff
          "bing".metaData.hidden = true;
          "google".metaData.hidden = true;
        };
      };

      # ─── Extensions via rycee's NUR (hash-pinned in Nix store) ───
      # Proton Pass + Proton VPN are not in the NUR — they're force-installed
      # via policies.ExtensionSettings above.
      extensions.packages =
        with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
          ublock-origin
          clearurls
          bitwarden
        ];
    };
  };
}
