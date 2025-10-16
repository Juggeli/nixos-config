{ channels, inputs, ... }:

final: prev: {
  ghostty-bin = channels.unstable.ghostty-bin;
}
