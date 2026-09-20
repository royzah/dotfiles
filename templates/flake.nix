{
  description = "Dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          # === Runtimes (uncomment what you need; stable as of Aug 2026) ===
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
    };
}
