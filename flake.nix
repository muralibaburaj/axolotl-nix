{
  description = "Nix package for Axolotl Launcher, auto-updated from upstream releases";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (import nixpkgs { inherit system; })
        );
    in
    {
      packages = forAllSystems (pkgs: rec {
        axolotl-launcher = pkgs.callPackage ./package.nix { };
        default = axolotl-launcher;
      });

      overlays.default = final: _prev: {
        axolotl-launcher = final.callPackage ./package.nix { };
      };

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = nixpkgs.lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
