{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, systems, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
        # plv8 = 
        #   let 
        #     pkgs = nixpkgs.legacyPackages.${system};
        #     inherit (pkgs) stdenv lib fetchFromGitHub v8 perl postgresql runCommand coreutils gnugrep;
        # in
        # stdenv.mkDerivation (finalAttrs: {
        #   pname = "plv8";
        #   version = "3.2.0";
        #   src = ./.;
        #
        #   # src = fetchFromGitHub {
        #   #   owner = "plv8";
        #   #   repo = "plv8";
        #   #   rev = "v${finalAttrs.version}";
        #   #   hash = "sha256-LodC2eQJSm5fLckrjm2RuejZhmOyQMJTv9b0iPCnzKQ=";
        #   # };
        #
        #   # patches = [
        #   #   # Allow building with system v8.
        #   #   # https://github.com/plv8/plv8/pull/505 (rejected)
        #   #   ./0001-build-Allow-using-V8-from-system.patch
        #   # ];
        #
        #   nativeBuildInputs = [
        #     perl
        #   ];
        #
        #   buildInputs = [
        #     v8
        #     postgresql
        #   ];
        #
        #   buildFlags = [ "all" ];
        #
        #   makeFlags = [
        #     # Nixpkgs build a v8 monolith instead of separate v8_libplatform.
        #     "USE_SYSTEM_V8=1"
        #     "SHLIB_LINK=-lv8"
        #     "V8_OUTDIR=${v8}/lib"
        #   ];
        #
        #   installFlags = [
        #     # PGXS only supports installing to postgresql prefix so we need to redirect this
        #     "DESTDIR=${placeholder "out"}"
        #   ];
        #
        #   # No configure script.
        #   dontConfigure = true;
        #
        #   postPatch = ''
        #     patchShebangs ./generate_upgrade.sh
        #     # https://github.com/plv8/plv8/pull/506
        #     substituteInPlace generate_upgrade.sh \
        #       --replace " 2.3.10 " " 2.3.10 2.3.11 2.3.12 2.3.13 2.3.14 2.3.15 "
        #   '';
        #
        #   postInstall = ''
        #     # Move the redirected to proper directory.
        #     # There appear to be no references to the install directories
        #     # so changing them does not cause issues.
        #     mv "$out/nix/store"/*/* "$out"
        #     rmdir "$out/nix/store"/* "$out/nix/store" "$out/nix"
        #   '';
        #
        #   passthru = {
        #     tests =
        #       let
        #         postgresqlWithSelf = postgresql.withPackages (_: [
        #           finalAttrs.finalPackage
        #         ]);
        #       in {
        #         smoke = runCommand "plv8-smoke-test" {} ''
        #           export PATH=${lib.makeBinPath [
        #             postgresqlWithSelf
        #             coreutils
        #             gnugrep
        #           ]}
        #           db="$PWD/testdb"
        #           initdb "$db"
        #           postgres -k "$db" -D "$db" &
        #           pid="$!"
        #
        #           for i in $(seq 1 100); do
        #             if psql -h "$db" -d postgres -c "" 2>/dev/null; then
        #               break
        #             elif ! kill -0 "$pid"; then
        #               exit 1
        #             else
        #               sleep 0.1
        #             fi
        #           done
        #
        #           psql -h "$db" -d postgres -c 'CREATE EXTENSION plv8; DO $$ plv8.elog(NOTICE, plv8.version); $$ LANGUAGE plv8;' 2> "$out"
        #           grep -q "${finalAttrs.version}" "$out"
        #           kill -0 "$pid"
        #         '';
        #
        #         regression = stdenv.mkDerivation {
        #           name = "plv8-regression";
        #           inherit (finalAttrs) src patches nativeBuildInputs buildInputs dontConfigure;
        #
        #           buildPhase = ''
        #             runHook preBuild
        #
        #             # The regression tests need to be run in the order specified in the Makefile.
        #             echo -e "include Makefile\nprint_regress_files:\n\t@echo \$(REGRESS)" > Makefile.regress
        #             REGRESS_TESTS=$(make -f Makefile.regress print_regress_files)
        #
        #             ${postgresql}/lib/pgxs/src/test/regress/pg_regress \
        #               --bindir='${postgresqlWithSelf}/bin' \
        #               --temp-instance=regress-instance \
        #               --dbname=contrib_regression \
        #               $REGRESS_TESTS
        #
        #             runHook postBuild
        #           '';
        #
        #           installPhase = ''
        #             runHook preInstall
        #
        #             touch "$out"
        #
        #             runHook postInstall
        #           '';
        #         };
        #       };
        #   };
        #
        #   meta = with lib; {
        #     description = "V8 Engine Javascript Procedural Language add-on for PostgreSQL";
        #     homepage = "https://plv8.github.io/";
        #     maintainers = with maintainers; [ marsam ];
        #     license = licenses.postgresql;
        #     broken = postgresql.jitSupport;
        #   };
        # });
      });

      devShells = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  packages = [ 
                    pkgs.cmake
                  ];
                  languages.cplusplus.enable = true;
                }
              ];
            };
          });
    };
}
