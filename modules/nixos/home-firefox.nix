{
  flake.nixosModules.home-firefox =
    { pkgs, ... }:
    let
      defaultSettings = {
        "devtools.theme" = "dark";
        "browser.contentblocking.category" = "strict";
        "privacy.donottrackheader.enabled" = true;
        "privacy.donottrackheader.value" = 1;
        "privacy.purge_trackers.enabled" = true;
        "services.sync.prefs.sync.browser.uiCustomization.state" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.download.dir" = "/home/juggeli/downloads";
        "signon.rememberSignons" = false;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.newtabpage.enabled" = false;
        "browser.newtab.url" = "about:blank";
        "browser.newtabpage.activity-stream.enabled" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.newtabpage.enhanced" = false;
        "browser.newtabpage.introShown" = true;
        "browser.newtab.preload" = false;
        "browser.newtabpage.directory.ping" = "";
        "browser.newtabpage.directory.source" = "data:text/plain,{}";
        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.shortcuts.bookmarks" = false;
        "browser.urlbar.shortcuts.history" = false;
        "browser.urlbar.shortcuts.tabs" = false;
        "browser.urlbar.showSearchSuggestionsFirst" = false;
        "browser.urlbar.speculativeConnect.enabled" = false;
        "browser.urlbar.dnsResolveSingleWordsAfterSearch" = 0;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.trimURLs" = false;
        "browser.disableResetPrompt" = true;
        "browser.onboarding.enabled" = false;
        "browser.aboutConfig.showWarning" = false;
        "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
        "extensions.pocket.enabled" = false;
        "extensions.shield-recipe-client.enabled" = false;
        "reader.parse-on-load.enabled" = false;

        "security.family_safety.mode" = 0;
        "security.pki.sha1_enforcement_level" = 1;
        "security.tls.enable_0rtt_data" = false;
        "geo.provider.network.url" =
          "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
        "geo.provider.use_gpsd" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "extensions.htmlaboutaddons.discover.enabled" = false;
        "extensions.getAddons.showPane" = false;
        "browser.discovery.enabled" = false;
        "browser.sessionstore.interval" = "1800000";
        "dom.battery.enabled" = false;
        "beacon.enabled" = false;
        "browser.send_pings" = false;
        "dom.gamepad.enabled" = false;
        "browser.fixup.alternate.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.server" = "data:,";
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.coverage.opt-out" = true;
        "toolkit.coverage.opt-out" = true;
        "toolkit.coverage.endpoint.base" = "";
        "experiments.supported" = false;
        "experiments.enabled" = false;
        "experiments.manifest.uri" = "";
        "browser.ping-centre.telemetry" = false;
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";
        "app.shield.optoutstudies.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.healthreport.service.enabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;

        "breakpad.reportURL" = "";
        "browser.tabs.crashReporting.sendReport" = false;
        "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;

        "browser.formfill.enable" = false;
        "extensions.formautofill.addresses.enabled" = false;
        "extensions.formautofill.available" = "off";
        "extensions.formautofill.creditCards.available" = false;
        "extensions.formautofill.creditCards.enabled" = false;
        "extensions.formautofill.heuristics.enabled" = false;
      };
    in
    {
      home-manager.users.juggeli = {
        programs.firefox = {
          enable = true;
          package = pkgs.firefox-bin;

          profiles.juggeli = {
            extraConfig = "";
            userChrome = "";
            settings = defaultSettings;
            extensions.force = true;
            id = 0;
            name = "juggeli";
          };
        };

        home.sessionVariables = {
          BROWSER = "firefox";
        };

        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "text/html" = [ "firefox.desktop" ];
            "x-scheme-handler/http" = [ "firefox.desktop" ];
            "x-scheme-handler/https" = [ "firefox.desktop" ];
            "x-scheme-handler/about" = [ "firefox.desktop" ];
            "x-scheme-handler/unknown" = [ "firefox.desktop" ];
          };
        };
      };

      environment.persistence."/persist-home" = {
        users.juggeli.directories = [
          ".cache/mozilla"
          ".mozilla"
        ];
      };
    };
}
