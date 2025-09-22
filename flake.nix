{
  description = "neovim";

  inputs = {
    # fleet.url = github:iff/fleet;
    # nixpkgs.follows = "fleet/nixpkgs";
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;

    flake-utils.url = github:numtide/flake-utils;

    # life on the cutting edge
    # neovim-nightly-overlay = {
    #   url = github:nix-community/neovim-nightly-overlay;
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    hop-nvim = {
      url = github:smoka7/hop.nvim;
      flake = false;
    };

    fugitive-nvim = {
      url = github:tpope/vim-fugitive;
      flake = false;
    };

    funky-formatter-nvim = {
      url = github:dkuettel/funky-formatter.nvim;
      flake = false;
    };

    lavish-layouts-nvim = {
      url = github:dkuettel/lavish-layouts.nvim;
      flake = false;
    };

    auspicious-autosave-nvim = {
      url = github:dkuettel/auspicious-autosave.nvim;
      flake = false;
    };

    funky-contexts-nvim = {
      url = github:dkuettel/funky-contexts.nvim;
      flake = false;
    };

    comment-nvim = {
      url = github:numToStr/Comment.nvim;
      flake = false;
    };

    nightfox-nvim = {
      url = github:EdenEast/nightfox.nvim;
      flake = false;
    };

    web-devicons-nvim = {
      url = github:nvim-tree/nvim-web-devicons;
      flake = false;
    };

    lualine-nvim = {
      url = github:nvim-lualine/lualine.nvim;
      flake = false;
    };

    nvim-lspconfig = {
      url = github:neovim/nvim-lspconfig;
      flake = false;
    };

    # nvim-cmp = {
    #   url = github:hrsh7th/nvim-cmp;
    #   flake = false;
    # };

    cmp-lsp-nvim = {
      url = github:hrsh7th/cmp-nvim-lsp;
      flake = false;
    };

    luasnip-nvim = {
      url = github:L3MON4D3/LuaSnip;
      flake = false;
    };

    cmp-buffer-nvim = {
      url = github:hrsh7th/cmp-buffer;
      flake = false;
    };

    cmp-path-nvim = {
      url = github:hrsh7th/cmp-path;
      flake = false;
    };

    cmp-luasnip-nvim = {
      url = github:saadparwaiz1/cmp_luasnip;
      flake = false;
    };

    lspkind-nvim = {
      url = github:onsails/lspkind.nvim;
      flake = false;
    };

    # plenary-nvim = {
    #   url = github:nvim-lua/plenary.nvim;
    #   flake = false;
    # };

    telescope-nvim = {
      url = github:nvim-telescope/telescope.nvim;
      flake = false;
    };

    telescope-fzf-native-nvim = {
      url = github:nvim-telescope/telescope-fzf-native.nvim;
      flake = false;
    };

    telescope-hop-nvim = {
      url = github:nvim-telescope/telescope-hop.nvim;
      flake = false;
    };

    telescope-ui-select-nvim = {
      url = github:nvim-telescope/telescope-ui-select.nvim;
      flake = false;
    };

    # rustacean-nvim = {
    #   url = github:mrcjkb/rustaceanvim;
    #   flake = true;
    # };

    kmonad-vim = {
      url = github:kmonad/kmonad-vim;
      flake = false;
    };

    resty-vim = {
      url = github:lima1909/resty.nvim;
      flake = false;
    };

    ptags-nvim = {
      url = github:dkuettel/ptags.nvim;
      flake = true;
    };
  };

  outputs = { self, flake-utils, nixpkgs, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            # neovim-nightly-overlay.overlays.default
          ];
        };

        plib = import ./lib { inherit pkgs inputs; };
        lib = nixpkgs.lib.extend (final: prev: plib);
        prod = import ./package.nix { pkgs = pkgs; inputs = inputs; inherit lib; dev-plugins = { }; };
        dev = import ./package.nix {
          pkgs = pkgs;
          inputs = inputs;
          inherit lib;
          dev-plugins = {
            # e.g. something like this:
            # auspicious-autosave-nvim = lib.plugLocal "auspicious-autosave-nvim" /path/to/local/autosave.nvim {};
          };
        };

        tv = pkgs.writeScriptBin "tv" ''
          #!${pkgs.zsh}/bin/zsh
          set -eu -o pipefail
          path=(${dev}/bin $path) ${dev}/bin/v $@
        '';

      in
      {
        packages = {
          default = dev;
          dev = dev;
          prod = prod;
        };

        apps.default = {
          type = "app";
          program = tv;
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            tv
          ];

          shellHook = ''
            # TODO
          '';
        };
      }
    );
}
