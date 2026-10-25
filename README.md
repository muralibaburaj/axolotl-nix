# axolotl-nix

Nix flake packaging [Axolotl Launcher](https://github.com/Axolotl-Launcher/Axolotl), an open-source Minecraft launcher, for `x86_64-linux` and `aarch64-linux`.

The package wraps the official `.deb` release in an FHS environment that provides the native libraries Minecraft needs (OpenGL, GLFW, OpenAL, PipeWire/PulseAudio, Vulkan, etc.).

A GitHub Action checks for new upstream releases every 6 hours, bumps `sources.json`, verifies the build, and commits the update automatically.

## Usage

Run it directly:

```sh
nix run github:muralibaburaj/axolotl-nix
```

Add it to a NixOS / Home Manager flake:

```nix
{
  inputs.axolotl.url = "github:muralibaburaj/axolotl-nix";

  outputs = { nixpkgs, axolotl, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            axolotl.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
        })
      ];
    };
  };
}
```

Or use the overlay: `nixpkgs.overlays = [ axolotl.overlays.default ];` then `pkgs.axolotl-launcher`.

### Extra environment variables

```nix
pkgs.axolotl-launcher.override {
  launchEnv = {
    # e.g. work around blank windows with NVIDIA drivers
    WEBKIT_DISABLE_DMABUF_RENDERER = 1;
  };
}
```

## Updating manually

```sh
./update.sh
```
