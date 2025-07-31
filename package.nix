{ pkgs, inputs, dev-plugins }:
let
  treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: with p; [
    c
    javascript
    json
    cpp
    go
    python
    typescript
    rust
    bash
    html
    haskell
    regex
    css
    toml
    nix
    clojure
    latex
    lua
    make
    markdown
    vim
    yaml
    glsl
    dockerfile
    graphql
    bibtex
    cmake
  ]);

  plug = name: pkgs.vimUtils.buildVimPlugin {
    pname = name;
    version = "git";
    src = builtins.getAttr name inputs;
    buildPhase = ''
      ${if name == "telescope-fzf-native-nvim" then "make" else ""}
    '';
    # hack to fix build tests
    dependencies = [
      pkgs.vimPlugins.nvim-cmp
      pkgs.vimPlugins.plenary-nvim
      pkgs.vimPlugins.telescope-nvim
    ];
    # TODO or
    # doCheck = false;
  };

  # TODO how to pair the plugins with their setup
  # TODO some plugins need some compilation step?
  plugins = (with pkgs.vimPlugins;
    [
      (plug "hop-nvim")
      (plug "fugitive-nvim")
      # (plug "gitsigns-nvim")
      gitsigns-nvim
      (plug "lsp-indicator-nvim")
      (plug "auspicious-autosave-nvim")
      (plug "lavish-layouts-nvim")
      (plug "funky-formatter-nvim")
      (plug "funky-contexts-nvim")
      (plug "comment-nvim")

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
      (plug "cmp-path-nvim")
      (plug "cmp-luasnip-nvim")
      (plug "lspkind-nvim")
      (plug "ptags-nvim")

      # telescope
      # (plug "plenary-nvim")
      plenary-nvim
      (plug "telescope-nvim")
      (plug "telescope-fzf-native-nvim")
      (plug "telescope-hop-nvim")
      (plug "telescope-ui-select-nvim")

      # (plug "rustacean-nvim")
      rustaceanvim

      (plug "neodev-nvim")
      (plug "kmonad-vim")
      (plug "resty-vim")

      treesitter
    ]) ++ (with dev-plugins; [
    # TODO
  ]);

  pluginsWithDependencies = pkgs.lib.unique (builtins.concatMap getDependencies plugins);
  # TODO is that still true? do plugins bring their dependencies?
  getDependencies = plugin: [ plugin ] ++ (builtins.concatMap getDependencies (plugin.dependencies or [ ]));
  packs = pkgs.runCommandLocal "packs" { } ''
    mkdir -p $out/pack/default/start/
    cd $out/pack/default/start
    ${pkgs.lib.concatMapStringsSep "\n" linkInPlugin pluginsWithDependencies}
  '';
  linkInPlugin = plugin: "ln -sfT ${plugin} ${pkgs.lib.getName plugin}";

  minimal = pkgs.writeTextFile {
    name = "init.lua";
    text = ''
      do
          vim.opt.runtimepath = {
              "${pkgs.neovim-unwrapped}/share/nvim/runtime",
              "${pkgs.neovim-unwrapped}/lib/nvim",
              "${./config}",
              "${./config}/after",
          }
          vim.opt.packpath = {
              "${pkgs.neovim-unwrapped}/share/nvim/runtime",
              "${pkgs.neovim-unwrapped}/lib/nvim",
              "${packs}",
          }

          require("yi.options").setup()
          require("yi.theme").setup()
          require("yi.options").set()

          -- no config
          require("Comment").setup()
          require("auspicious-autosave").setup()

          -- my config
          require("yi.hop").setup()
          require("yi.telescope").setup()
          require("yi.completion").setup()
          require("yi.lsp").setup(require("yi.completion").get_capabilities())
          require("yi.fugitive").setup()
          require("yi.formatter").setup()
          require("yi.diagnostic").setup()
          require("yi.treesitter").setup()

          require("yi.mappings").apply()
      end
    '';
  };

  # TODO might have been better before? "NVIM_APPNAME=nvim-e exec -a $0 ${pkgs.neovim-unwrapped}/bin/nvim -u ${minimal(false)} -V1 $@"
  bin-v = pkgs.writeScriptBin "v" ''
    #!${pkgs.zsh}/bin/zsh
    set -eu -o pipefail
    if NVIM_APPNAME=nvim-e ${pkgs.neovim-unwrapped}/bin/nvim -u ${minimal} $@; then
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
    # TODO install neovim-nightly
    neovim-unwrapped
    #
    fd
    ripgrep
    basedpyright
    clang-tools
    pyright
    sumneko-lua-language-server
    yaml-language-server
    # formatters
    black
    nixpkgs-fmt
    nodePackages.prettier
    nodePackages.typescript-language-server
    stylua
    taplo
  ]);

  postBuild = ''
    ln -sfT ${bin-v}/bin/v $out/bin/v
  '';
}
