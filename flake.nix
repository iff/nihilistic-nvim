{
  description = "neovim";

  inputs = {
    # fleet.url = "github:iff/fleet";
    # nixpkgs.follows = "fleet/nixpkgs";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    # life on the cutting edge
    # neovim-nightly-overlay = {
    #   url = "github:nix-community/neovim-nightly-overlay";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    hop-nvim = {
      url = "github:smoka7/hop.nvim";
      flake = false;
    };

    fugitive-nvim = {
      url = "github:tpope/vim-fugitive";
      flake = false;
    };

    funky-formatter-nvim = {
      url = "github:dkuettel/funky-formatter.nvim";
      flake = false;
    };

    lavish-layouts-nvim = {
      url = "github:dkuettel/lavish-layouts.nvim";
      flake = false;
    };

    auspicious-autosave-nvim = {
      url = "github:dkuettel/auspicious-autosave.nvim";
      flake = false;
    };

    mad-mappings-nvim = {
      url = "github:dkuettel/mad-mappings.nvim";
      flake = false;
    };

    nightfox-nvim = {
      url = "github:EdenEast/nightfox.nvim";
      flake = false;
    };

    lualine-nvim = {
      url = "github:nvim-lualine/lualine.nvim";
      flake = false;
    };

    nvim-lspconfig = {
      url = "github:neovim/nvim-lspconfig";
      flake = false;
    };

    telescope-nvim = {
      url = "github:nvim-telescope/telescope.nvim";
      flake = false;
    };

    telescope-fzf-native-nvim = {
      url = "github:nvim-telescope/telescope-fzf-native.nvim";
      flake = false;
    };

    telescope-hop-nvim = {
      url = "github:nvim-telescope/telescope-hop.nvim";
      flake = false;
    };

    telescope-ui-select-nvim = {
      url = "github:nvim-telescope/telescope-ui-select.nvim";
      flake = false;
    };

    # rustacean-nvim = {
    #   url = "github:mrcjkb/rustaceanvim";
    #   flake = true;
    # };

    resty-vim = {
      url = "github:lima1909/resty.nvim";
      flake = false;
    };

    ptags-nvim = {
      url = "github:dkuettel/ptags.nvim";
      flake = true;
    };
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            # neovim-nightly-overlay.overlays.default
          ];
        };

        plib = import ./lib { inherit pkgs inputs; };
        lib = nixpkgs.lib.extend (final: prev: plib);

        devPluginNames = [
          "mad-mappings-nvim"
        ];

        worldPlugins = with pkgs.vimPlugins; [
          (lib.plug "auspicious-autosave-nvim")
          (lib.plug "lavish-layouts-nvim")
          (lib.plug "funky-formatter-nvim")
          # (lib.plug "mad-mappings-nvim")
          (lib.plugNoCheck "ptags-nvim")

          (lib.plug "hop-nvim")
          (lib.plug "fugitive-nvim")
          gitsigns-nvim
          oil-nvim
          kmonad-vim
          (lib.plugNoCheck "resty-vim")

          # theme
          (lib.plug "nightfox-nvim")
          (lib.plug "lualine-nvim")
          nvim-web-devicons

          # lsp (minimal)
          (lib.plug "nvim-lspconfig")
          nvim-cmp
          cmp-nvim-lsp
          cmp-buffer
          cmp-path
          luasnip
          cmp_luasnip
          lspkind-nvim

          # (lib.plugNoCheck "rustacean-nvim")
          # rustaceanvim

          # telescope
          plenary-nvim
          (lib.plugNoCheck "telescope-nvim")
          (lib.plug "telescope-fzf-native-nvim")
          (lib.plug "telescope-hop-nvim")
          (lib.plug "telescope-ui-select-nvim")

          pkgs.vimPlugins.nvim-treesitter.withAllGrammars
        ];

        devPlugins = map lib.plugNoCheck devPluginNames;
        devPluginPaths =
          (map (name: "./plugins/${name}") devPluginNames)
          ++ (map (name: "./plugins/${name}/after") devPluginNames);

        # TODO flake in project should install the deps!
        dependencies-lsps = with pkgs; [
          basedpyright
          clang-tools
          emmylua-ls
          lua-language-server
          yaml-language-server
          nodePackages.typescript-language-server
          nil
        ];
        dependencies-formatters = with pkgs; [
          stylua
          taplo
          nodePackages.prettier
          nixfmt
        ];
        dependencies-telescope = with pkgs; [
          fd
          ripgrep
        ];
        dependencies = dependencies-lsps ++ dependencies-formatters ++ dependencies-telescope;

        plugins = worldPlugins ++ devPlugins;
        # TODO is that still true? do plugins bring their dependencies?
        # TODO does pkgs.lib.unique here really work as intended? can it properly compare those things?
        pluginsWithDependencies = pkgs.lib.unique (builtins.concatMap getWithDependencies plugins);
        getWithDependencies =
          plugin: [ plugin ] ++ (builtins.concatMap getWithDependencies (plugin.dependencies or [ ]));
        dependencyPlugins = pkgs.lib.subtractLists plugins pluginsWithDependencies;

        # TODO is getName guaranteed to never clash? maybe not use -f?
        linkInPlugin = plugin: "ln -sfT ${plugin} ${pkgs.lib.getName plugin}";
        packs =
          dev:
          pkgs.runCommandLocal "packs" { } ''
            mkdir -p $out/pack/dependencies/start/
            cd $out/pack/dependencies/start
            ${pkgs.lib.concatMapStringsSep "\n" linkInPlugin dependencyPlugins}

            mkdir -p $out/pack/prod/start/
            cd $out/pack/prod/start
            ${pkgs.lib.concatMapStringsSep "\n" linkInPlugin (if dev then worldPlugins else plugins)}

            cd $out
            touch paths
            ls -d pack/dependencies/start/*/ >> $out/paths
            ls -d pack/prod/start/*/ >> $out/paths
          '';
        # TODO deprecated, copied out, it says "use list instead", but I dont understand how
        readPathsFromFile =
          rootPath: file:
          let
            lines = pkgs.lib.splitString "\n" (builtins.readFile file);
            removeComments = pkgs.lib.filter (line: line != "" && !(pkgs.lib.hasPrefix "#" line));
            relativePaths = removeComments lines;
            absolutePaths = map (path: rootPath + "/${path}") relativePaths;
          in
          absolutePaths;
        packPaths = dev: readPathsFromFile "${packs dev}" "${packs dev}/paths";

        configJson =
          dev:
          pkgs.writeTextFile {
            name = "config.json";
            text = builtins.toJSON {
              runtimepath = [
                (if dev then "./config" else "${./config}")
                "${pkgs.neovim-unwrapped}/share/nvim/runtime"
                "${pkgs.neovim-unwrapped}/lib/nvim"
              ]
              ++ (if dev then devPluginPaths else [ ])
              ++ [
                # TODO not sure we need to add after explicitely
                (if dev then "./config/after" else "${./config}/after")
              ];
              packpath = [
                "${packs dev}"
                "${pkgs.neovim-unwrapped}/share/nvim/runtime"
                "${pkgs.neovim-unwrapped}/lib/nvim"
              ];
              config = if dev then "./config" else "${./config}";
              nvim_runtime = "${pkgs.neovim-unwrapped}/share/nvim/runtime";
              nvim_lib = "${pkgs.neovim-unwrapped}/lib/nvim";
              config_after = if dev then "./config/after" else "${./config}/after";
              packs = packPaths dev;
            };
          };

        initLua =
          config:
          pkgs.writeTextFile {
            name = "init.lua";
            text = ''
              local file = io.open("${config}")
              local json = file:read("*a")
              file:close()
              local config = vim.json.decode(json)
              vim.opt.runtimepath = config.runtimepath
              vim.opt.packpath = config.packpath
              require("yi.main").main()
            '';
          };

        configJsonProd = configJson false;
        initLuaProd = initLua configJsonProd;

        bin-v = pkgs.writeScriptBin "v" ''
          #!${pkgs.zsh}/bin/zsh
          set -eu -o pipefail
          if [[ ''${__use_neovide:-no} == yes ]]; then
              exe=(neovide --fork --neovim-bin ${pkgs.neovim-unwrapped}/bin/nvim --)
          else
              exe=(${pkgs.neovim-unwrapped}/bin/nvim)
          fi
          if NVIM_APPNAME=nvim-e $exe -u ${initLuaProd} ''${@:-.}; then
              exit 0
          else
              ret=$?
              if [[ -e ./reload-session.vim ]]; then
                  exec $0 -S ./reload-session.vim
              fi
              exit $ret
          fi
        '';

        bins = [
          bin-v
        ];

        package = pkgs.symlinkJoin {
          name = "nvim";
          paths =
            bins
            ++ [
              pkgs.neovim-unwrapped
              inputs.ptags-nvim.packages.${pkgs.stdenv.hostPlatform.system}.app
              # inputs.funky-formatter-nvim.packages.${pkgs.stdenv.hostPlatform.system}.default
            ]
            ++ dependencies;
          postBuild = ''
            ln -sfT $out/bin/e $out/bin/nvim
          '';
        };

        luarcMain = pkgs.writeTextFile {
          name = "luarc-main";
          destination = "/luarcs/main.json";
          text = builtins.toJSON {
            "runtime.version" = "LuaJIT";
            "runtime.pathStrict" = true;
            # TODO we dont add /after right now, not sure this is ever needed? its a bit messy the alternative
            "runtime.path" = [
              "lua/?.lua"
              "lua/?/init.lua"
            ];
            # TODO we also add packs here, in theory nvim runtime could also have packs? didnt see any last time I checked
            "workspace.library" = [
              "${pkgs.neovim-unwrapped}/share/nvim/runtime"
              "${pkgs.neovim-unwrapped}/lib/nvim"
              # "../plugins/ptags.nvim"
            ]
            ++ (packPaths true);
          };
        };

        # TODO just one for now, but they are not the same technically, just lazy, giving them all telescope
        luarcPlugins = pkgs.writeTextFile {
          name = "luarc-plugins";
          destination = "/luarcs/plugin.json";
          text = builtins.toJSON {
            "runtime.version" = "LuaJIT";
            "runtime.pathStrict" = true;
            "runtime.path" = [
              "lua/?.lua"
              "lua/?/init.lua"
            ];
            "workspace.library" = [
              "${pkgs.neovim-unwrapped}/share/nvim/runtime"
              "${pkgs.neovim-unwrapped}/lib/nvim"
              "${pkgs.vimPlugins.telescope-nvim}"
            ];
          };
        };

        configJsonDev = configJson true;
        initLuaDev = initLua configJsonDev;
        bin-nvim-dev = pkgs.writeScriptBin "nvim-dev" ''
          #!${pkgs.zsh}/bin/zsh
          set -eu -o pipefail
          NVIM_APPNAME=nvim-e ${pkgs.neovim-unwrapped}/bin/nvim -u ${initLuaDev} ''${@:-.}
        '';

        dev = pkgs.symlinkJoin {
          name = "nvim-dev";
          paths = [
            bin-nvim-dev
            luarcMain
            luarcPlugins
            package
          ];
        };

      in
      {
        packages = {
          default = package;
          dev = dev;
        };
      }
    );
}
