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
              extraPackages = [
                "ninja"
                # FIXME: why are these needed here?
                "pkg-config"
                "rosidl-default-generators"
                # "geometry-msgs"
                "rosidl-default-runtime"
                "rosidl-typesupport-c"
                "rosidl-typesupport-cpp"
                "ament-cmake"
                "mc-rtc-magnum"
              ];
              extraDevPackages = [ "pkg-config" ];
              overrideAttrs.mc-panda = {
                src = lib.cleanSource /home/arnaud/devel/mc-rtc-nix/workspace/mc_panda;
                # cmakeFlags = drv-prev.cmakeFlags ++ [
                #   "-DPYTHON_BINDINGS=OFF"
                # ];
              };
              overrideAttrs.mc-panda-lirmm = {
                src = lib.cleanSource /home/arnaud/devel/mc-rtc-nix/workspace/mc_panda_lirmm;
              };
              overrideAttrs.panda-prosthesis = {
                src = lib.cleanSource ./.;
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
                  };
                };

            };
          }
        ];
        perSystem =
          { pkgs, ... }:
          {
            devShells.polytopeController-superbuild = pkgs.callPackage "${inputs.mc-rtc-nix}/shell.nix" {
              inherit pkgs;
              mc-rtc-superbuild = pkgs.mc-rtc-superbuild;
            };
          };
      }
    );
}
