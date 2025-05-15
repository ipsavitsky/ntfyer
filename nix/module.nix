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
      inherit (ntfyer.${config.nixpkgs.system}) default;
    };

    configurationFile = lib.mkOption {
      type = lib.types.path;
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "ntfyer";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "ntfyer";
    };
  };

  config = lib.mkIf cfg.enable {

    users.users = lib.mkIf (cfg.user == "ntfyer") {
      ntfyer = {
        group = cfg.group;
        isSystemUser = true;
      };
    };

    users.groups = lib.mkIf (cfg.group == "ntfyer") {
      ntfyer = { };
    };

    systemd.services.ntfyer = {
      serviceConfig = {
        ExecStart = ''
          ${cfg.package}/bin/ntfyer \
            -c ${cfg.configurationFile}
        '';
        Restart = "on-failure";
        User = cfg.user;
        Group = cfg.group;
      };

      wantedBy = [ "multi-user.target" ];
    };
  };
}
