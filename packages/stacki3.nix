{ lib, python3 }:

with python3.pkgs;

buildPythonApplication rec {
    pname = "stacki3";
    version = "1.0.0";

    src = fetchPypi {
        inherit pname version;
        sha256 = "34e61217edf8191a02775b208ea5e4113b15a2fb2e87e1354c498120e02c5fb6";
    };

    propagatedBuildInputs = [
        i3ipc
    ];

    doCheck = false;

    meta = {
        homepage = "https://github.com/ViliamV/stacki3";
        description = "Simple stack layout for i3/sway wm.";
        license = lib.licenses.mit;
        platforms = [ "x86_64-linux" ];
        maintainers = [];
    };
}