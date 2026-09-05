{
  python3,
  writeShellScriptBin,
  lib,
  keyFile,
}:
writeShellScriptBin "publish-plan" ''
  if [ -z "''${PLANS_KEY_FILE:-}" ]; then
    export PLANS_KEY_FILE=${lib.escapeShellArg keyFile}
  fi
  exec ${python3}/bin/python3 ${./publish.py} "$@"
''
