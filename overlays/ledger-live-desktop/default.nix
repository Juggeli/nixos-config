{ channels, ... }:

final: prev:

{
  inherit (channels.unstable) ledger-live-desktop;
}
