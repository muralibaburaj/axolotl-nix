{
  lib,
  stdenv,
  fetchurl,
  buildFHSEnv,
  makeDesktopItem,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,

  glib-networking,
  libayatana-appindicator,
  librsvg,
  webkitgtk_4_1,

  # Extra environment variables exported when the launcher starts
  launchEnv ? { },
}:

let
  sources = lib.importJSON ./sources.json;
  inherit (sources) version;
  arch =
    {
      x86_64-linux = "amd64";
      aarch64-linux = "arm64";
    }
    .${stdenv.hostPlatform.system}
      or (throw "axolotl-launcher: unsupported system ${stdenv.hostPlatform.system}");

  meta = {
    description = "Open-source, cross-platform Minecraft launcher (Modrinth App fork)";
    homepage = "https://github.com/Axolotl-Launcher/Axolotl";
    changelog = "https://github.com/Axolotl-Launcher/Axolotl/releases/tag/v${version}";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "axolotl-launcher";
  };

  unwrapped = stdenv.mkDerivation {
    pname = "axolotl-launcher-unwrapped";
    inherit version meta;

    src = fetchurl {
      url = "https://github.com/Axolotl-Launcher/Axolotl/releases/download/v${version}/Axolotl.Launcher_${version}_${arch}.deb";
      hash = sources.hashes.${arch};
    };

    nativeBuildInputs = [
      dpkg
      autoPatchelfHook
      wrapGAppsHook3
    ];

    buildInputs = [
      glib-networking
      librsvg
      webkitgtk_4_1
    ];

    # Tray icon support is dlopen()ed at runtime
    runtimeDependencies = [ libayatana-appindicator ];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x $src .
      runHook postUnpack
    '';

    # Tauri resolves its resources at <exe>/../lib/<productName>, so keep the layout
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r usr/bin usr/lib usr/share $out/
      runHook postInstall
    '';
  };

  desktopItem = makeDesktopItem {
    name = "axolotl-launcher";
    desktopName = "Axolotl Launcher";
    exec = "axolotl-launcher %U";
    icon = "axolotl-launcher";
    categories = [ "Game" ];
    mimeTypes = [
      "application/x-modrinth-modpack+zip"
      "x-scheme-handler/axolotl"
    ];
    startupWMClass = "Axolotl Launcher";
  };
in
# FHS env so that the Minecraft instances the launcher spawns find their native libraries
buildFHSEnv {
  pname = "axolotl-launcher";
  inherit version;

  targetPkgs =
    pkgs: with pkgs; [
      unwrapped
      # Launcher
      libnotify
      libayatana-appindicator
      cacert
      # Minecraft
      stdenv.cc.cc.lib
      glfw3-minecraft
      openal
      alsa-lib
      libjack2
      libpulseaudio
      pipewire
      libGL
      libx11
      libxcursor
      libxext
      libxrandr
      libxxf86vm
      wayland
      udev
      vulkan-loader
      flite
      gamemode
      libusb1
    ];

  # NVIDIA's libEGL finds its Wayland/GBM platform libraries via the host's
  # /etc/egl; without it EGL falls back to Mesa, which ends up on llvmpipe
  extraBwrapArgs = [ "--ro-bind-try /etc/egl /etc/egl" ];

  profile = ''
    set -o allexport
    ${lib.toShellVars launchEnv}
    set +o allexport
  '';

  runScript = "'${unwrapped}/bin/Axolotl Launcher'";

  extraInstallCommands = ''
    install -Dm644 ${desktopItem}/share/applications/*.desktop -t $out/share/applications
    for size in 128x128 256x256@2; do
      install -Dm644 "${unwrapped}/share/icons/hicolor/$size/apps/Axolotl Launcher.png" \
        "$out/share/icons/hicolor/$size/apps/axolotl-launcher.png"
    done
  '';

  passthru = {
    inherit unwrapped;
    updateScript = ./update.sh;
  };

  inherit meta;
}
