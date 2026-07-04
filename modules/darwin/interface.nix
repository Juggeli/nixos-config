{
  flake.darwinModules.interface =
    { pkgs, ... }:
    {
      system.defaults = {
        dock = {
          autohide = true;
          orientation = "left";
          tilesize = 32;

          persistent-apps = [
            "/Applications/Zen.app"
            "${pkgs.ghostty-bin}/Applications/Ghostty.app"
            "/Applications/Discord.app"
            "/System/Applications/System Settings.app"
          ];

          show-recents = false;
          show-process-indicators = true;

          wvous-bl-corner = 1;
          wvous-br-corner = 1;
          wvous-tl-corner = 1;
          wvous-tr-corner = 1;
        };

        finder = {
          AppleShowAllExtensions = true;
          CreateDesktop = false;
          FXDefaultSearchScope = "SCcf";
          FXPreferredViewStyle = "Nlsv";
          ShowPathbar = true;
          ShowStatusBar = true;
          _FXShowPosixPathInTitle = true;
          FXEnableExtensionChangeWarning = false;
        };

        NSGlobalDomain = {
          _HIHideMenuBar = false;
          AppleShowScrollBars = "Always";
          AppleInterfaceStyle = "Dark";
          AppleShowAllExtensions = true;
          NSDisableAutomaticTermination = false;
          NSNavPanelExpandedStateForSaveMode = true;
          NSNavPanelExpandedStateForSaveMode2 = true;
        };

        loginwindow.GuestEnabled = false;

        screencapture.type = "png";

        CustomUserPreferences = {
          "com.apple.desktopservices" = {
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
          "com.apple.NetworkBrowser".BrowseAllInterfaces = true;
          "com.apple.finder" = {
            NewWindowTarget = "PfLo";
            NewWindowTargetPath = "file://\${HOME}";
            _FXSortFoldersFirst = true;
          };
          "com.apple.assistant.support" = {
            "Assistant Enabled" = false;
          };
          "com.apple.Siri" = {
            StatusMenuVisible = false;
            UserHasDeclinedEnable = true;
          };
        };
      };

      home-manager.users.juggeli.home.file.".hushlogin".text = "";
    };
}
