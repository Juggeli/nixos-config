{ channels, ... }:

final: prev:

{
  inherit (channels.unstable) jackett;
}
