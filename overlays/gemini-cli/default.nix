{ channels, inputs, ... }:

final: prev: {
  gemini-cli = channels.unstable.gemini-cli;
}
