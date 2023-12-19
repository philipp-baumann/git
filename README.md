# My nix development environment for git repositories

# Introduction

This is the nix flake config for managing my git development environment
on my M2 macbook air.

The goal is to automatically activate the Nix shell defined in
`flake.nix`, once you navigate into `$HOME/git` and to specific
subfolders.

- [`nix-direnv`](https://github.com/nix-community/nix-direnv) is set up
  via home-manager.

``` sh
# in `$HOME/.config/home-manager/home.nix`
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };
```

The file `.envrc` makes `nix-direnv` use flakes.

``` sh
# in ./.envrc
use flake .
```

To build and activate the nix shell environment, execute

``` sh
cd $HOME/git
direnv activate
```