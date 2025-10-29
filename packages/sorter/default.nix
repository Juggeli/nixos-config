{
  lib,
  buildGoModule,
  mpv,
  makeWrapper,
  pkg-config,
  gcc,
  ffmpeg,
  xorg,
  libGL,
  libGLU,
}:

buildGoModule {
  pname = "sorter";
  version = "1.0.0";

  src = ../../tools/sorter;

  vendorHash = "sha256-kVrz8FYO/2lkW1oVG8bmA2J+8aHqx/YFpIpi25QTw2I=";

  nativeBuildInputs = [
    makeWrapper
    pkg-config
    gcc
  ];

  buildInputs = [
    ffmpeg
    mpv
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXi
    xorg.libXxf86vm
    libGL
    libGLU
  ];

  postInstall = ''
    wrapProgram $out/bin/sorter \
      --prefix PATH : ${lib.makeBinPath [ mpv ]}
  '';

  meta = with lib; {
    description = "Interactive TUI media file sorter";
    homepage = "https://github.com/plusultra/dotfiles";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
