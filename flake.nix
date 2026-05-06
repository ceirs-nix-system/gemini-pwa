{
  description = "PWA Desktop Nix";
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";

  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          configData = builtins.readFile ./config.json;
          configJson=builtins.fromJSON (configData);
          name = configJson.name;
          pkgs = import nixpkgs {
            inherit system;
          };
          desktopFile = ''
            [Desktop Entry]
            Type=Application
            Name=${name}
            Exec=$out/bin/${name}
            Icon=./icon.svg
            Terminal=false
            Keywords=${configJson.keywords}
            Comment=${configJson.description}
          '';
        in
        {
          default = pkgs.buildNpmPackage rec {
            pname = name;
            version = "1.0";
            src = ./app;

            npmDepsHash = "sha256-3tIHllTGByjFaRW3piJJtkuuzRhAnJ+P76OEJ9HbCDM=";
            dontNpmBuild = true;
            env = {
              ELECTRON_SKIP_BINARY_DOWNLOAD = 1;
            };

            postInstall = ''
              makeWrapper ${pkgs.electron}/bin/electron $out/bin/${pname} \
                --add-flags $out/lib/node_modules/pwa-desktop-nix/src/main.js \
                --set PWA_URL "${configJson.url}"
              mkdir -p $out/share/applications
              cp $out/lib/node_modules/pwa-desktop-nix/assets/icon.svg $out/share/applications/icon.svg
              echo "${desktopFile}" > $out/share/applications/${pname}.desktop
            '';

            meta = {
              homepage = "https://github.com/udontur/${pname}";
              mainProgram = pname;
              license = pkgs.lib.licenses.mit;
              platforms = pkgs.lib.platforms.all;
            };
          };
        }
      );
    };
}
