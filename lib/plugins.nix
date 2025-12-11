{ pkgs, inputs }:

rec {
  # Build a vim plugin from inputs with custom options
  plugWith =
    name:
    {
      doCheck ? true,
    }:
    pkgs.vimUtils.buildVimPlugin {
      pname = name;
      version = "git";
      src = builtins.getAttr name inputs;
      buildPhase = ''
        ${if name == "telescope-fzf-native-nvim" then "make" else ""}
      '';
      # TODO fix doCheck and get deps as argument?
      # inherit dependencies;
      # dependencies = with pkgs.vimPlugins [
      #   nvim-cmp
      #   plenary-nvim
      #   telescope-nvim
      # ];
      inherit doCheck;
    };

  plug = name: plugWith name { doCheck = true; };
  plugNoCheck = name: plugWith name { doCheck = false; };
}
