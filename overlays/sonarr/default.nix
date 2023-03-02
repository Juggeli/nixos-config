{ channels, ... }:

final: prev:

{
  inherit (channels.unstable) sonarr;
}
