{
  description = "My nix development environment for git repositories";
  
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils}:
    
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        system_packages = builtins.attrValues {
          inherit (pkgs)
            R
            glibcLocalesUtf8;
        };
        git_archive_pkgs = [(pkgs.rPackages.buildRPackage {
          name = "r-polars";
          src = pkgs.fetchgit {
            url = "https://github.com/pola-rs/r-polars";
            branchName = "main";
            rev = "cb367e0b3b11683d57b4f4f3a70cbb32e7815134";
            sha256 = "sha256-1RnJGGBgpDPqNUBIWQMsNcRD/qNG5XnEqFJoqPw873I=";
        };
        propagatedBuildInputs = builtins.attrValues {
          inherit (pkgs.rPackages) codetools rextendr;
          inherit (pkgs) cmake curl cacert openssl rustc cargo;
        };
        buildPhase = ''
            export HOME=$TMP
            export RPOLARS_PROFILE="release-optimized"
        '';
  }) ];
        rpkgs = builtins.attrValues {
          inherit (pkgs.rPackages)
            data_table
            devtools
            remotes
            future
            future_apply
            targets
            dplyr
            renv
            rextendr
            sf;
        };
        rust_pkgs = builtins.attrValues {
          inherit (pkgs)
            clippy
            rustc
            cargo
            rustfmt
            rust-analyzer;
        };
      in {
        devShells.default = pkgs.mkShell {
          LOCALE_ARCHIVE = if 
            pkgs.system == "x86_64-linux" 
            then  "${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive" else "";
          LANG = "en_US.UTF-8";
          LC_ALL = "en_US.UTF-8";
          LC_TIME = "en_US.UTF-8";
          LC_MONETARY = "en_US.UTF-8";
          LC_PAPER = "en_US.UTF-8";
          LC_MEASUREMENT = "en_US.UTF-8";
          
          # `propagatedBuildInputs` is for run-time dependencies

          # build-time dependencies
          buildInputs = [
            system_packages
            git_archive_pkgs
            rpkgs
            rust_pkgs
          ];

          # https://churchman.nl/2019/03/10/using-nix-to-create-r-virtual-environments/
          
          # shellHook = ''
          #   mkdir -p "$(pwd)/_libs"
          #   export R_LIBS_USER="$(pwd)/_libs"
          # '';
        };
      }
  );
}
