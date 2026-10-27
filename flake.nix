{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };    

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core, homebrew-cask }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ pkgs.vim
	  pkgs.zoom-us
	  pkgs.signal-desktop
	  pkgs.github-cli
	  pkgs.pnpm
	  pkgs.fnm
	  pkgs.gcc
	  pkgs.bun
	  pkgs.neovim
	  pkgs.cargo
	  pkgs.ripgrep
	  pkgs.deno
	  pkgs.ffmpeg
	  pkgs.rsync
	  pkgs.pv
	  pkgs.tmux
        ];

      homebrew = {
        enable = true;

	onActivation.cleanup = "uninstall";
	onActivation.upgrade = false;
	taps = [ "homebrew/homebrew-core" "homebrew/homebrew-cask" ];
	
	brews = [
	  "xcodegen"
	  "iperf3"
	  "coreutils"
	  "mise"
	];

	casks = [
	  "topnotch"
	  "ghostty"
	  "cloudflare-warp"
	  "tailscale-app"
	  "notion-mail"
	  "discord@ptb"
	  "adobe-creative-cloud"
	  "blip"
	  "zed"
	  "claude"
	  "steam"
	  "prismlauncher"
	  "linearmouse"
	  "autodesk-fusion"
	  "jetbrains-toolbox"
	  "blender"
	  "bambu-studio"
	  "betterdisplay"
	  "godspeed"
	  "firefox"
	  "librewolf"
	  "plover"
	  "actual"
	  "balenaetcher"
	];
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      nixpkgs.config.allowUnfree = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      system.primaryUser = "benjaminxia";

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#benjaminxia
    darwinConfigurations."benjaminxia" = nix-darwin.lib.darwinSystem {
      modules = [
	./alloy.nix
	configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "benjaminxia";

            # Optional: Declarative tap management
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };

            # Optional: Enable fully-declarative tap management
            #
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            mutableTaps = false;
          };
        }
      ];
    };
  };
}
