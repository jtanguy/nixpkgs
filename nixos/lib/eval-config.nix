# From an end-user configuration file (`configuration.nix'), build a NixOS
# configuration object (`config') from which we can retrieve option
# values.

# !!! Please think twice before adding to this argument list!
# Ideally eval-config.nix would be an extremely thin wrapper
# around lib.evalModules, so that modular systems that have nixos configs
# as subcomponents (e.g. the container feature, or nixops if network
# expressions are ever made modular at the top level) can just use
# types.submodule instead of using eval-config.nix
evalConfigArgs@
{ # !!! system can be set modularly, would be nice to remove
  system ? builtins.currentSystem
, # !!! is this argument needed any more? The pkgs argument can
  # be set modularly anyway.
  pkgs ? null
, # !!! what do we gain by making this configurable?
  baseModules ? import ../modules/module-list.nix
, # !!! See comment about args in lib/modules.nix
  extraArgs ? {}
, # !!! See comment about args in lib/modules.nix
  specialArgs ? {}
, modules
, # !!! See comment about check in lib/modules.nix
  check ? true
, prefix ? []
, lib ? import ../../lib
, extraModules ? let e = builtins.getEnv "NIXOS_EXTRA_MODULE_PATH";
                 in if e == "" then [] else [(import e)]
}:

let pkgs_ = pkgs;
in

let
  pkgsModule = rec {
    _file = ./eval-config.nix;
    key = _file;
    config = {
      # Explicit `nixpkgs.system` or `nixpkgs.localSystem` should override
      # this.  Since the latter defaults to the former, the former should
      # default to the argument. That way this new default could propagate all
      # they way through, but has the last priority behind everything else.
      nixpkgs.system = lib.mkDefault system;

      # Stash the value of the `system` argument. When using `nesting.children`
      # we want to have the same default value behavior (immediately above)
      # without any interference from the user's configuration.
      nixpkgs.initialSystem = system;

      _module.args.pkgs = lib.mkIf (pkgs_ != null) (lib.mkForce pkgs_);
    };
  };

  withWarnings = x:
    lib.warnIf (evalConfigArgs?extraArgs) "The extraArgs argument to eval-config.nix is deprecated. Please set config._module.args instead."
    lib.warnIf (evalConfigArgs?check) "The check argument to eval-config.nix is deprecated. Please set config._module.check instead."
    x;

  legacyModules =
    lib.optional (evalConfigArgs?extraArgs) {
      config = {
        _module.args = extraArgs;
      };
    }
    ++ lib.optional (evalConfigArgs?check) {
      config = {
        _module.check = lib.mkDefault check;
      };
    };
  allUserModules = modules ++ legacyModules;

  noUserModules = lib.evalModules ({
    inherit prefix;
    modules = baseModules ++ extraModules ++ [ pkgsModule modulesModule ];
    specialArgs =
      { modulesPath = builtins.toString ../modules; } // specialArgs;
  });

  # Extra arguments that are useful for constructing a similar configuration.
  modulesModule = {
    config = {
      _module.args = {
        inherit noUserModules baseModules extraModules modules;
      };
    };
  };

  nixosWithUserModules = noUserModules.extendModules { modules = allUserModules; };

in withWarnings {

  # Merge the option definitions in all modules, forming the full
  # system configuration.
  inherit (nixosWithUserModules) config options _module type;

  inherit extraArgs;

  inherit (nixosWithUserModules._module.args) pkgs;
}
