{ pkgs, inputs, lib, dev-plugins }:
let
  inherit (lib) plug plugNoCheck;

  basePluginsList = with pkgs.vimPlugins; [
    (plug "hop-nvim")
    (plug "fugitive-nvim")
    gitsigns-nvim
    (plug "auspicious-autosave-nvim")
    (plug "lavish-layouts-nvim")
    (plug "funky-formatter-nvim")
    (plug "funky-contexts-nvim")
    (plug "comment-nvim")
    oil-nvim

    # theme
    (plug "nightfox-nvim")
    (plug "web-devicons-nvim")
    (plug "lualine-nvim")

    # lsp (minimal)
    (plug "nvim-lspconfig")
    # (plug "nvim-cmp")
    nvim-cmp
    (plug "cmp-lsp-nvim")
    (plug "luasnip-nvim")

    # lsp (ext completion)
    (plug "cmp-buffer-nvim")
    (plugNoCheck "cmp-path-nvim")
    (plugNoCheck "cmp-luasnip-nvim")
    (plug "lspkind-nvim")
    (plugNoCheck "ptags-nvim")

    # telescope
    # (plug "plenary-nvim")
    plenary-nvim
    (plugNoCheck "telescope-nvim")
    (plug "telescope-fzf-native-nvim")
    (plug "telescope-hop-nvim")
    (plug "telescope-ui-select-nvim")

    (plugNoCheck "rustacean-nvim")
    # rustaceanvim

    (plug "kmonad-vim")
    (plugNoCheck "resty-vim")

    pkgs.vimPlugins.nvim-treesitter.withAllGrammars
  ];

  devPluginsList = builtins.attrValues dev-plugins;

  # dev-plugins take precedence - filter out base plugins that have same name as dev plugins
  devPluginNames = map pkgs.lib.getName devPluginsList;
  filteredBasePlugins = builtins.filter (plugin: !(builtins.elem (pkgs.lib.getName plugin) devPluginNames)) basePluginsList;
  plugins = devPluginsList ++ filteredBasePlugins;

  pluginsWithDependencies = pkgs.lib.unique (builtins.concatMap getDependencies plugins);
  # TODO is that still true? do plugins bring their dependencies?
  getDependencies = plugin: [ plugin ] ++ (builtins.concatMap getDependencies (plugin.dependencies or [ ]));
  packs = pkgs.runCommandLocal "packs" { } ''
    mkdir -p $out/pack/default/start/
    cd $out/pack/default/start
    ${pkgs.lib.concatMapStringsSep "\n" linkInPlugin pluginsWithDependencies}

    cd $out
    touch paths
    ls -d pack/dependencies/start/*/ >> $out/paths
    ls -d pack/prod/start/*/ >> $out/paths
  '';
  linkInPlugin = plugin: "ln -sfT ${plugin} ${pkgs.lib.getName plugin}";
  packPaths = pkgs.lib.unique (builtins.filter (x: x != "") (pkgs.lib.splitString "\n" (builtins.readFile "${packs}/paths")));

  luarc = pkgs.writeTextFile {
    name = "luarcjson";
    destination = "/luarcs/main.json";
    text = builtins.toJSON {
      "runtime.version" = "LuaJIT";
      "runtime.pathStrict" = true;
      # we dont add /after right now
      "runtime.path" = [ "lua/?.lua" "lua/?/init.lua" ];
      "workspace.library" = [
        "${pkgs.neovim-unwrapped}/share/nvim/runtime"
        "${pkgs.neovim-unwrapped}/lib/nvim"
      ] ++ packPaths;
    };
  };

  minimal = pkgs.writeTextFile {
    name = "init.lua";
    text = ''
      vim.opt.runtimepath = {
          "${./config}",
          "${pkgs.neovim-unwrapped}/share/nvim/runtime",
          "${pkgs.neovim-unwrapped}/lib/nvim",
          "${./config}/after",
      }
      vim.opt.packpath = {
          "${packs}",
          "${pkgs.neovim-unwrapped}/share/nvim/runtime",
          "${pkgs.neovim-unwrapped}/lib/nvim",
      }
      require("yi.main").main()
    '';
  };

  # TODO might have been better before? "NVIM_APPNAME=nvim-e exec -a $0 ${pkgs.neovim-unwrapped}/bin/nvim -u ${minimal()} -V1 $@"
  bin-v = pkgs.writeScriptBin "v" ''
    #!${pkgs.zsh}/bin/zsh
    set -eu -o pipefail
    if NVIM_APPNAME=nvim-e ${pkgs.neovim}/bin/nvim -u ${minimal} $@; then
        exit 0
    else
        ret=$?
        if [[ -e ./reload-session.vim ]]; then
            exec $0 -S ./reload-session.vim
        fi
        exit $ret
    fi
  '';

in
pkgs.symlinkJoin {
  name = "nvim";
  paths = [
    inputs.ptags-nvim.packages.${pkgs.system}.app
  ] ++ (with pkgs; [
    # neovim-nightly from overlay
    neovim-unwrapped
    luarc
    #
    fd
    ripgrep
    # lang servers
    basedpyright
    clang-tools
    emmylua-ls
    lua-language-server
    yaml-language-server
    nodePackages.typescript-language-server
    nil
    # formatters
    nixpkgs-fmt
    nodePackages.prettier
    stylua
    taplo
  ]);

  postBuild = ''
    ln -sfT ${bin-v}/bin/v $out/bin/nvim
    ln -sfT ${bin-v}/bin/v $out/bin/v
  '';
}
