{ channels, ... }:

final: prev:

{
  inherit (channels.unstable) home-assistant;
}
