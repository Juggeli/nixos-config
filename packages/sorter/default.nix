{
  lib,
  buildGoModule,
  mpv,
  makeWrapper,
}:

buildGoModule {
  pname = "sorter";
  version = "1.0.0";

  src = ../../tools/sorter;

  vendorHash = "sha256-sYOuMihX/Z2Pw2+qOWQQwFBH7R4u1cV4+E/scRey7Hg=";

  nativeBuildInputs = [ makeWrapper ];

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
