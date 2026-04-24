{
  lib,
  rustPlatform,
  swwwSrc,
  libxkbcommon,
  lz4,
  makeWrapper,
  pkg-config,
  procps,
  wayland,
  wayland-protocols,
  wayland-scanner,
}:

rustPlatform.buildRustPackage rec {
  pname = "swww";
  version = "0.11.2";

  src = swwwSrc;

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = [
    makeWrapper
    pkg-config
    wayland
    wayland-protocols
    wayland-scanner
  ];

  buildInputs = [
    libxkbcommon
    lz4
    wayland
    wayland-protocols
  ];

  env = {
    WAYLAND_CLIENT_PKGDATADIR = "${wayland}/share/wayland";
    WAYLAND_SCANNER_PKGDATADIR = "${wayland}/share/wayland";
  };

  preBuild = ''
    export PKG_CONFIG_PATH="${wayland.dev}/lib/pkgconfig:${wayland-scanner}/lib/pkgconfig:$PKG_CONFIG_PATH"
  '';

  postInstall = ''
    wrapProgram "$out/bin/swww" \
      --prefix PATH : ${lib.makeBinPath [ procps ]}
  '';

  meta = {
    description = "Efficient animated wallpaper daemon for Wayland";
    homepage = "https://github.com/LGFae/swww";
    license = lib.licenses.gpl3Only;
    mainProgram = "swww";
    platforms = lib.platforms.linux;
  };
}
