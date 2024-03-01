{ config, lib, ... }:

with lib;
with lib.plusultra;
let cfg = config.plusultra.system.interface;
in
{
  options.plusultra.system.interface = with types; {
    enable = mkEnableOption "macOS interface";
  };

  config = mkIf cfg.enable {
    system.defaults = {
      dock = {
        autohide = true;
        orientation = "left";

        # Disable hot corners.
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
      };

      finder = {
        AppleShowAllExtensions = true;
        # Don't show icons on the desktop.
        CreateDesktop = false;
        # Search in the current folder, instead of the whole mac.
        FXDefaultSearchScope = "SCcf";
        # Defeault to the list view in Finder windows.
        FXPreferredViewStyle = "Nlsv";
        # Show the pathbar, which gives us breadcrumbs to the current folder.
        ShowPathbar = true;
        # Show the status bar, which has some useful metadata.
        ShowStatusBar = true;
        # Use the POSIX path in the finder title, rather than just the folder name.
        _FXShowPosixPathInTitle = true;
        FXEnableExtensionChangeWarning = false;
      };

      NSGlobalDomain = {
        _HIHideMenuBar = true;
        AppleShowScrollBars = "Always";
        # Always use dark mode.
        AppleInterfaceStyle = "Dark";
        # Always show file extensions in Finder.
        AppleShowAllExtensions = true;
        # Don't automatically terminate inactive apps.
        NSDisableAutomaticTermination = false;
        # Always start with Save dialog panels expanded.
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
      };

      # Don't provide a Guest account.
      loginwindow.GuestEnabled = false;

      # Default to capturing screenshots in PNG.
      screencapture.type = "png";

      CustomUserPreferences = {
        # Avoid creating .DS_Store files on network or USB volumes.
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        # Enable AirDrop over Ethernet
        "com.apple.NetworkBrowser".BrowseAllInterfaces = true;
        ## Finder options not yet internalized by Nix.
        "com.apple.finder" = {
          # Start new Finder sessions in our home folder.
          NewWindowTarget = "PfLo";
          NewWindowTargetPath = "file://\${HOME}";
          # Keep folders at the top of the Finder lists.
          _FXSortFoldersFirst = true;
        };
      };
    };

    plusultra.home.file.".hushlogin".text = "";
  };
}

