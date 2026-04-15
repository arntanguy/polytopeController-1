{
  description = "PandaProsthesis controller for the Rolkneematics project";

  inputs = {
    mc-rtc-nix.url = "github:mc-rtc/nixpkgs";
    # mc-rtc-nix.url = "path:/home/arnaud/devel/mc-rtc-nix/nixpkgs";
    # mc-rtc-nix.url = "github:arntanguy/nixpkgs-1?ref=topic/flakoboros";
    flake-parts.follows = "mc-rtc-nix/flake-parts";
    systems.follows = "mc-rtc-nix/systems";
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
              extraDevPackages = [ "pkg-config" ];
              overrideAttrs.mc-force-shoe-plugin =
                { pkgs-final, ... }:
                {
                  # src = lib.cleanSource /home/arnaud/devel/mc-rtc-nix/workspace/mc_force_shoe_plugin;

                  # https://github.com/Hugo-L3174/mc_force_shoe_plugin/pull/16
                  src = pkgs-final.fetchFromGitHub {
                    owner = "arntanguy";
                    repo = "mc_force_shoe_plugin";
                    rev = "d3c6a5b9f84c67fd25f8c6ccc0396d5a9572d579";
                    hash = "sha256-mFwizoWXQFV6uKIG7AcbPd40Mio4vvsrQGtngtaiSTY=";
                  };
                };
              overrideAttrs.mc-state-observation =
                { pkgs-final, ... }:
                {
                  src = pkgs-final.fetchgit {
                    url = "https://github.com/arntanguy/mc_state_observation.git";
                    rev = "1a56ad133d26cb0fa80c4359380fb5934ad7ce6e";
                    hash = "sha256-sIY0mwNQkPDnqD7KssQ0OD851rQI3Q8kiPxVGB4+WAA=";
                    fetchSubmodules = true;
                  };
                };

              overrideAttrs.dcm-vrptask =
                { pkgs-final, ... }:
                {
                  src = pkgs-final.fetchFromGitHub {
                    owner = "arntanguy";
                    repo = "DCM_VRPTask";
                    rev = "5ceb14fbfebb82b704b4c8629b9a4d0e300f3153";
                    hash = "sha256-eIwSAAjkPj+SjQOQ0okSCD+QmwL0DL8IGOZsrH1AK4Y=";
                  };
                };

              overrideAttrs.mc-dynamic-polytopes =
                { pkgs-final, ... }:
                {
                  src = pkgs-final.fetchgit {
                    url = "https://github.com/arntanguy/mc_dynamic_polytopes.git";
                    # PR#6
                    rev = "d4d27c78dbedf03c82234c4b579d511072e62c73"; # or a commit hash or branch name
                    hash = "sha256-qhoD7qYgsjxcfKYo+tzu7X123tZwEJ0qy9cXP9b8UTQ=";
                  };
                };

              overrideAttrs.tvm =
                { pkgs-final, ... }:
                {
                  src = pkgs-final.fetchgit {
                    # tvm pr 53
                    url = "https://github.com/Hugo-L3174/tvm.git";
                    rev = "0c66fac37db38f2e5bc4f3df2b418f3ae50cea68";
                    sha256 = "sha256-wLalEmtXO4Id8PFtVoJD9KzCU4QKeAv/xp5mCjDvpnA=";
                  };
                };

              overrideAttrs.mc-rtc =
                { pkgs-final, ... }:
                {
                  pname = "mc-rtc-hugo";
                  src = pkgs-final.fetchgit {
                    url = "https://github.com/arntanguy/mc_rtc.git";
                    rev = "206a46008d6ade6d8e400263a88b62301e75fc57";
                    sha256 = "sha256-DRyjyBjr+CBkQjFt9y9DdtV7UBLzr3ImIjsk7e0uiM8=";
                  };
                };

              overrideAttrs.polytopeController = {
                src = lib.cleanSource ./.;
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
            devShells.polytopeController-superbuild =
              (pkgs.callPackage "${inputs.mc-rtc-nix}/shell.nix" {
                inherit pkgs;
                mc-rtc-superbuild = pkgs.mc-rtc-superbuild;
                #
                # POLYTOPECONTROLLER = "${pkgs.polytopeController}/lib/mc_controller/etc/mc_rtc.yaml:${pkgs.mc-rtc-superbuild}/etc/mc_rtc.yaml";
                # POLYTOPECONTROLLER_MUJOCO = "${pkgs.polytopeController}/lib/mc_controller/etc/mc_rtc.yaml:${pkgs.mc-rtc-superbuild}/etc/mc_rtc.yaml";
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
