{ ntfyer }:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.ntfyer;
in
{
  options.services.ntfyer = {
    enable = lib.mkEnableOption "a daemon that redirect notifications from ntfy to your machine";

    package = lib.mkOption {
      type = lib.types.package;
      inherit (ntfyer.${pkgs.system}) default;
    };

    configurationFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.ntfyer = {
      Service = {
        ExecStart = ''
          ${cfg.package}/bin/ntfyer \
            -c ${cfg.configurationFile}
        '';
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
