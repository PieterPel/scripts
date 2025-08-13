{
  description = "Flake to make a script to convert a typst or pdf file to pptx";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    forAllSystems (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        name = "typ-to-pptx";
        buildInputs = with pkgs; [
          imagemagick
          ghostscript_headless
          parallel
          zip
          typst
        ];
        script =
          pkgs.runCommandLocal name
            {
              buildInputs = [ pkgs.makeWrapper ];
            }
            ''
              mkdir -p $out/bin
              mkdir -p $out/bin/pdf2pptx
              cp ${./convert.sh} $out/bin/${name}
              cp -r ${./pdf2pptx}/* $out/bin/pdf2pptx/
              chmod +x $out/bin/${name}
              chmod +x $out/bin/pdf2pptx/pdf2pptx.sh
              patchShebangs $out
              wrapProgram $out/bin/${name} --prefix PATH : ${pkgs.lib.makeBinPath buildInputs}
            '';
      in
      rec {
        defaultPackage = packages.${name};
        packages.${name} = pkgs.symlinkJoin {
          inherit name;
          paths = [ script ] ++ buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
        };
      }
    );
}
