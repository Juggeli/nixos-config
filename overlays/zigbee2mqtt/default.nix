{ channels, ... }:

final: prev:

{
  inherit (channels.unstable) zigbee2mqtt;
}
