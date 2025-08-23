{ channels, inputs, ... }:

final: prev: {
  claude-code = channels.unstable.claude-code;
}
