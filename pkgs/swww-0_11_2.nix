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

  postPatch = ''
    substituteInPlace daemon/build.rs \
      --replace-fail "WaylandProtocol::Client," \
        'WaylandProtocol::Local(PathBuf::from("${wayland}/share/wayland/wayland.xml")),'
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
