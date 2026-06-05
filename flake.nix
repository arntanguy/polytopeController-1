{
  description = "PandaProsthesis controller for the Rolkneematics project";

  inputs = {
    mc-rtc-nix.url = "github:mc-rtc/nixpkgs";
    flake-parts.follows = "mc-rtc-nix/flake-parts";
    systems.follows = "mc-rtc-nix/systems";

    # or use pull/N/merge to get the version merged with master, assuming there are no conflicts

    mc-state-observation.url = "github:jrl-umi3218/mc_state_observation/pull/57/head";
    mc-state-observation.flake = false;

    dcm-vrptask.url = "github:Hugo-L3174/DCM_VRPTask/pull/1/head";
    dcm-vrptask.flake = false;

    mc-dynamic-polytopes.url = "github:Hugo-L3174/mc_dynamic_polytopes/pull/6/head";
    mc-dynamic-polytopes.flake = false;

    mc-force-shoe-plugin.url = "github:Hugo-L3174/mc_force_shoe_plugin/pull/16/head";

    # FIXME: can't do this because of benchmark submodule
    # tvm.url = "github:jrl-umi3218/tvm/pull/53/head";
    # tvm.flake = false;

    mc-rtc.url = "github:jrl-umi3218/mc_rtc/pull/507/head";
    # mc-rtc.url = "path:/home/arnaud/devel/mc-rtc-nix/workspace/mc_rtc";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        systems = import inputs.systems;
        imports = [
          inputs.mc-rtc-nix.flakeModulePrivate
          {
            flakoboros = {
              extraPackages = [ "ninja" ];

              overrideAttrs.polytopeController = {
                src = lib.cleanSource ./.;
              };

              # Override all dependencies
              # They are locked in flake.lock to the latest commit available at the time
              # To update to all inputs' latest commit, use
              # nix flake update
              overrideAttrs.mc-force-shoe-plugin = {
                src = inputs.mc-force-shoe-plugin;
              };

              overrideAttrs.mc-state-observation =
                { ... }:
                {
                  src = inputs.mc-state-observation;
                  # src = pkgs-final.fetchgit {
                  #   url = "https://github.com/arntanguy/mc_state_observation.git";
                  #   rev = "1a56ad133d26cb0fa80c4359380fb5934ad7ce6e";
                  #   hash = "sha256-sIY0mwNQkPDnqD7KssQ0OD851rQI3Q8kiPxVGB4+WAA=";
                  #   fetchSubmodules = true;
                  # };
                };

              overrideAttrs.dcm-vrptask = {
                src = inputs.dcm-vrptask;
              };

              overrideAttrs.politopix =
                { ... }:
                {
                  src =
                    builtins.trace "politopix is currently a private repository, ask I2S Bordeaux to make it public"
                      (
                        builtins.fetchGit {
                          url = "git@github.com:Hugo-L3174/politopix";
                          rev = "f625b42de4404eea16aabcf720f2cee19dfdc406";
                        }
                      );
                };

              overrideAttrs.mc-dynamic-polytopes = {
                src = inputs.mc-dynamic-polytopes;
              };

              overrideAttrs.tvm =
                { pkgs-final, ... }:
                {
                  src = pkgs-final.fetchgit {
                    # tvm pr 53
                    url = "https://github.com/Hugo-L3174/tvm.git";
                    rev = "4e6640660317dd9e311fc707de689c4cf984ee50";
                    sha256 = "sha256-Mzx7J3yp9pcoOf5VMkma1sNs8uCqjgnCsZZYlHBGLE4=";
                  };
                };

              overrideAttrs.mc-rtc =
                { ... }:
                {
                  pname = "mc-rtc-hugo";
                  src = inputs.mc-rtc;
                };

              overrides.mc-mujoco-robots =
                { pkgs-final, ... }:
                {
                  robots = with pkgs-final; [
                    hrp4-mj-description
                    rhps1-mj-description
                  ];
                };

              # overrides override package function arguments, while overrideAttrs overrides the attribute set
              overrides.mc-rtc-superbuild =
                { pkgs-final, pkgs-prev, ... }:
                let
                  cfg-prev = pkgs-prev.mc-rtc-superbuild.superbuildArgs;
                in
                {
                  superbuildArgs = cfg-prev // {
                    pname = "mc-rtc-superbuild-hugo";
                    robots = [ pkgs-final.mc-rhps1 ];
                    controllers = [ pkgs-final.polytopeController ];
                    configs = [ "${pkgs-final.polytopeController}/lib/mc_controller/etc/mc_rtc.yaml" ];
                    plugins = [ pkgs-final.mc-force-shoe-plugin ];
                    observers = [ pkgs-final.mc-state-observation ];
                  };
                };

            };
          }
        ];
        perSystem =
          { pkgs, ... }:
          {
            devShells.default =
              (pkgs.callPackage "${inputs.mc-rtc-nix}/shell.nix" {
                inherit (pkgs) mc-rtc-superbuild;
              }).overrideAttrs
                (old: {
                  shellHook = ''
                    ${old.shellHook or ""}

                    # Your custom shellHook commands
                    export POLYTOPE_CONTROLLER="${pkgs.polytopeController}/lib/mc_controller/etc/mc_rtc.yaml"
                    export POLYTOPE_CONTROLLER_MUJOCO="${pkgs.polytopeController}/lib/mc_controller/etc/mc_rtc_MuJoCo.yaml"
                  '';
                });
          };
      }
    );
}
