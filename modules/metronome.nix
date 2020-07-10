{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.metronome;
in
{
  options.services.metronome = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable Metronome IM
      '';
    };

    configFile = mkOption {
      type = types.path;
      default = pkgs.metronome + "/etc/metronome/metronome.cfg.lua";
      description = ''
        Metronome IM configuration file
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.etc = {
      # or symlinkJoin config file with this...
      # "metronome".source = pkgs.metronome + "/etc/metronome";

      "metronome/metronome.cfg.lua".source = cfg.configFile;
      "metronome/certs".source = pkgs.metronome + "/etc/metronome/certs";
      "metronome/templates".source = pkgs.metronome + "/etc/metronome/templates";
    };

    users = {
      users.metronome = {
        group = "metronome";
        description = "Metronome IM XMPP Server";
        home = "/var/lib/metronome";
      };

      groups.metronome = { };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/metronome 0755 metronome metronome"
      "d /var/log/metronome 0700 metronome metronome"
    ];

    systemd.services.metronome = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [ openssl metronome.lua ];
      description = "Instant Messaging (XMPP) Server";

      serviceConfig = {
        Type = "forking";
        User = "metronome";
        Group = "metronome";
        ExecStart = "${pkgs.metronome}/bin/metronomectl start";
        ExecStop = "${pkgs.metronome}/bin/metronomectl stop";

        PIDFile = "/run/metronome/metronome.pid";
        RuntimeDirectory = "metronome";
        RuntimeDirectoryMode = "0750";
      };
    };
  };
}
