        # the r-polars build setup is taken from
        # https://github.com/pola-rs/r-polars/blob/main/flake.nix
        # MIT License

        # Copyright (c) 2022 Søren Havelund Welling

        # Permission is hereby granted, free of charge, to any person obtaining a copy
        # of this software and associated documentation files (the "Software"), to deal
        # in the Software without restriction, including without limitation the rights
        # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        # copies of the Software, and to permit persons to whom the Software is
        # furnished to do so, subject to the following conditions:

        # The above copyright notice and this permission notice shall be included in all
        # copies or substantial portions of the Software.

        # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        # SOFTWARE.

{
  description = "My nix development environment for git repositories";
  
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.fenix.url = "github:nix-community/fenix";

  outputs = { self, nixpkgs, flake-utils, fenix}:
    
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        rustToolchains = fenix.packages.${system}.complete;
        rdeps = with pkgs; [
          curl
          fontconfig
          fribidi
          harfbuzz
          libjpeg
          libpng
          libtiff
          libxml2
          openssl
          pkg-config
        ];
        # Build r-polars from source
        rpolars = pkgs.rPackages.buildRPackage {
          name = "polars";
          src = self;
          cargoDeps = pkgs.rustPlatform.importCargoLock {
            lockFile = "${self}/r-polars/${rpolars.cargoRoot}/Cargo.lock";
            outputHashes = {};
            allowBuiltinFetchGit = true;
          };
          cargoRoot = "src/rust";
          nativeBuildInputs = with pkgs;
            [ cmake rPackages.codetools rustPlatform.cargoSetupHook ]
            ++ pkgs.lib.singleton rustToolchains.toolchain;
        };
        # Create R development environment with r-polars and other useful libraries
        rvenv = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [ devtools languageserver renv rextendr ];
        };
        system_packages = builtins.attrValues {
          inherit (pkgs)
            R
            glibcLocalesUtf8;
        };
        rpkgs = builtins.attrValues {
          inherit (pkgs.rPackages)
            data_table
            devtools
            remotes
            future
            future_apply
            targets
            dplyr
            renv;
            # install.packages("polars", repos = "https://rpolars.r-universe.dev")
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
        
          buildInputs = [
            rdeps
            system_packages
            rpkgs
          ];
          inputsFrom = pkgs.lib.singleton rpolars;
          packages = pkgs.lib.singleton rvenv;
          LD_LIBRARY_PATH = pkgs.lib.strings.makeLibraryPath rdeps;
          # https://churchman.nl/2019/03/10/using-nix-to-create-r-virtual-environments/
          
          shellHook = ''
            mkdir -p "$(pwd)/_libs"
            export R_LIBS_USER="$(pwd)/_libs"
          '';
        };
      }
  );
}
