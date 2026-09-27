{
  description = "neovim";

  inputs = {
    # fleet.url = "github:iff/fleet";
    # nixpkgs.follows = "fleet/nixpkgs";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    # hop-nvim = {
    #   url = "github:smoka7/hop.nvim";
    #   flake = false;
    # };

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

    everforest-nvim = {
      url = "github:neanias/everforest-nvim";
      flake = false;
    };

    nvim-lspconfig = {
      url = "github:neovim/nvim-lspconfig";
      flake = false;
    };

    nvim-treesitter-textobjects = {
      url = "github:nvim-treesitter/nvim-treesitter-textobjects";
      flake = false;
    };

    tree-sitter-lean = {
      url = "github:Julian/tree-sitter-lean";
      flake = false;
    };

    indent-blankline-nvim = {
      url = "github:lukas-reineke/indent-blankline.nvim";
      flake = false;
    };

    # rustacean-nvim = {
    #   url = "github:mrcjkb/rustaceanvim";
    #   flake = true;
    # };

    # resty-vim = {
    #   url = "github:lima1909/resty.nvim";
    #   flake = false;
    # };

    # ptags-nvim = {
    #   url = "github:dkuettel/ptags.nvim";
    #   flake = true;
    # };
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
          # (lib.plugNoCheck "ptags-nvim")

          hunk-nvim
          diffview-nvim
          jj-nvim
          # gitsigns-nvim
          mini-diff
          # oil-nvim
          kmonad-vim
          fidget-nvim
          # (lib.plug "hop-nvim")
          (lib.plug "fugitive-nvim")
          (lib.plugNoCheck "indent-blankline-nvim")

          # HTTP-Rest-Client plugin
          # (lib.plugNoCheck "resty-vim")

          # theme
          # catppuccin-nvim # -> did not like it
          (lib.plugNoCheck "everforest-nvim")
          (lib.plug "nightfox-nvim")
          mini-icons

          # lsp (minimal)
          (lib.plug "nvim-lspconfig")
          blink-cmp

          # (lib.plugNoCheck "rustacean-nvim")
          # rustaceanvim

          # pickers
          snacks-nvim
          flash-nvim
          plenary-nvim

          nvim-dap
          # nvim-dap-ui
          nvim-dap-view

          lean-nvim

          # treesitter
          (lib.plugNoCheck "nvim-treesitter-textobjects")
          treesitterPlugins
        ];

        treesitterPlugins = pkgs.vimPlugins.nvim-treesitter.withPlugins (
          _:
          pkgs.vimPlugins.nvim-treesitter.allGrammars
          ++ [
            (pkgs.tree-sitter.buildGrammar {
              language = "lean";
              version = "unstable-${inputs.tree-sitter-lean.shortRev or "dirty"}";
              src = inputs.tree-sitter-lean;
            })
          ]
        );

        devPlugins = map lib.plugNoCheck devPluginNames;
        devPluginPaths =
          (map (name: "./plugins/${name}") devPluginNames)
          ++ (map (name: "./plugins/${name}/after") devPluginNames);

        dependencies-pickers = with pkgs; [
          fd
          ripgrep
        ];

        # always install common formatters and nix lsp
        dependencies-lsp-fmt = with pkgs; [
          # lsps
          nil
          yaml-language-server
          # formatters
          nixfmt
          prettier
          stylua
          taplo
        ];
        dependencies = dependencies-pickers ++ dependencies-lsp-fmt;

        plugins = worldPlugins ++ devPlugins;
        pluginsWithDependencies = pkgs.lib.unique (builtins.concatMap getWithDependencies plugins);
        getWithDependencies =
          plugin: [ plugin ] ++ (builtins.concatMap getWithDependencies (plugin.dependencies or [ ]));
        dependencyPlugins = pkgs.lib.subtractLists plugins pluginsWithDependencies;

        treesitterDependencies = builtins.concatMap getWithDependencies (
          treesitterPlugins.dependencies or [ ]
        );
        dependenciesWithoutTreesitter = pkgs.lib.subtractLists treesitterDependencies dependencyPlugins;
        compactTreesitterDependencies = pkgs.buildEnv {
          name = "compact-treesitter";
          paths = treesitterDependencies;
        };
        compactDependencyPlugins = builtins.concatLists [
          dependenciesWithoutTreesitter
          [ compactTreesitterDependencies ]
        ];

        # TODO is getName guaranteed to never clash? maybe not use -f?
        linkInPlugin = plugin: "ln -sfT ${plugin} ${pkgs.lib.getName plugin}";
        packs =
          dev:
          pkgs.runCommandLocal "packs" { } ''
            mkdir -p $out/pack/dependencies/start/
            cd $out/pack/dependencies/start
            ${pkgs.lib.concatMapStringsSep "\n" linkInPlugin compactDependencyPlugins}

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
          NVIM_APPNAME=nvim-e exec $exe -u ${initLuaProd} ''${@:-}
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
              # inputs.ptags-nvim.packages.${pkgs.stdenv.hostPlatform.system}.default
              # inputs.funky-formatter-nvim.packages.${pkgs.stdenv.hostPlatform.system}.default
            ]
            ++ dependencies;

          # postBuild = ''
          #   ln -sfT $out/bin/e $out/bin/nvim
          # '';
        };

        # TODO emmylua doesnt offer a way yet to validate this json
        # and when it cant be parsed it is just ignored, no notification in nvim and hard to notice
        emmyrc = pkgs.writeTextFile {
          name = "emmyrc";
          destination = "/emmyrc.json";
          text = builtins.toJSON {
            "$schema" =
              "https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/refs/heads/main/crates/emmylua_code_analysis/resources/schema.json";
            runtime = {
              version = "LuaJIT";
              requirePattern = [
                "lua/?.lua"
                "lua/?/init.lua"
                # could add `after/lua/...`
              ];
            };
            doc = {
              syntax = "md";
            };
            strict = {
              requirePath = true;
              typeCall = true;
            };
            workspace = {
              # workspace entries contribute to workspace diagnostics
              # but I think the plugins arent really considered in an isolated fashion with this
              workspaceRoots = [
                "./config"
              ]
              ++ (map (n: "./plugins/${n}") devPluginNames);
              # library entries are indexed, goto-able, but dont contribute to project diagnostics
              library = [
                "${pkgs.neovim-unwrapped}/share/nvim/runtime"
                "${pkgs.neovim-unwrapped}/lib/nvim"
              ]
              # NOTE in theory nvim runtime could also have packPaths, didnt last time I checked, if a future version does, we are probably missing it here
              ++ (packPaths true);
            };
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
            package
          ];
        };

        build = pkgs.writeShellScriptBin "build" ''
          nix build -v --log-format internal-json |& nom --json
        '';

        build-dev = pkgs.writeShellScriptBin "dev" ''
          nix build '#dev' -v --log-format internal-json |& nom --json
        '';

      in
      {
        packages = {
          default = package;
          dev = dev;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            build
            build-dev
            nix-output-monitor
            #
            emmylua-ls
            # lua-language-server
          ];

          shellHook = ''
            # nd_env is a flake spec ([path:]dir[#name]), so reduce it to the directory
            root=''${h:-''${nd_env:-}}
            root=''${root#path:}
            root=''${root%%#*}
            if [[ -n $root ]]; then
              export PATH=$root/bin:$PATH;
              if [[ ! $root/.nd/state -ef $root/.nd/dev ]] then
                ln -sfT ${emmyrc}/emmyrc.json $root/.emmyrc.json
              fi
            else
              echo 'Project root unknown: neither h nor nd_env is set.' >&2
            fi
          '';
        };
      }
    );
}
