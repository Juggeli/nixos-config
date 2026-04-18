{ channels, inputs, ... }:

final: prev: {
  cloudflared = channels.unstable.cloudflared;
}
