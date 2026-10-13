{
  description = "Dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          # === Runtimes (uncomment what you need; stable as of Oct 2026) ===
          # python314
          # uv
          # nodejs_24
          # rustc
          # cargo
          # go

          # === Build tools ===
          # cmake
          # ninja
          # pkg-config
          # protobuf

          # === CLI ===
          jq
          yq
          just
          ripgrep
          fd
        ];

        # shellHook = ''
        #   echo "dev shell loaded"
        # '';
      };
    });
  };
}
