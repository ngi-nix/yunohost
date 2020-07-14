{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.yunohost;

  yunohost = pkgs.symlinkJoin {
    name = "yunohost-combined";
    paths = [ pkgs.yunohost pkgs.yunohost-admin ];
  };
in
{
  options.services.yunohost = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable YunoHost
      '';
    };

  };

# # allow users to access /media directory
# [[ -d /etc/skel/media ]] \
#   || (mkdir -p /media && ln -s /media /etc/skel/media)

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [ yunohost ];

    environment.etc = let
      caCertsDrv = pkgs.runCommand "ca-certs-drv" {
        nativeBuildInputs = [ pkgs.openssl ];
      } ''
        sed \
          -e "s@${yunohost}/share/yunohost@$out@g" \
          -e "s@/usr/share/yunohost@$out@g" \
          -e "s@/yunohost-config/ssl/yunoCA@@g" \
          ${yunohost}/share/yunohost/templates/ssl/openssl.cnf > openssl.cnf

        mkdir -p $out/newcerts
        touch $out/index.txt

        HOME=. openssl rand -hex 19 > $out/serial

        mkdir -p $out/ca
        HOME=. openssl req -x509 \
          -new \
          -config ./openssl.cnf \
          -days 3650 \
          -out "$out/ca/cacert.pem" \
          -keyout "$out/ca/cakey.pem" \
          -nodes -batch

        mkdir -p $out/certs
        HOME=. openssl req -new \
          -config ./openssl.cnf \
          -days 730 \
          -out "$out/certs/yunohost_csr.pem" \
          -keyout "$out/certs/yunohost_key.pem" \
          -nodes -batch

        HOME=. openssl ca \
          -config ./openssl.cnf \
          -days 730 \
          -in "$out/certs/yunohost_csr.pem" \
          -out "$out/certs/yunohost_crt.pem" \
          -batch
      '';
    in
    {
      "ssowat".source = pkgs.ssowat + "/etc/ssowat";

      # yunohost cli needs this to be present
      "yunohost/installed".text = "";

      # data/hooks/conf_regen/01-yunohost
      "yunohost/current_host".source = pkgs.writeText "current_host" "yunohost.org";
      "yunohost/services.yml".source = yunohost + "/share/yunohost/templates/yunohost/services.yml";
      "yunohost/firewall.yml".source = yunohost + "/share/yunohost/templates/yunohost/firewall.yml";

      # data/hooks/conf_regen/02-ssl
      # pre
      "yunohost/yunohost-config/ssl/yunoCA/openssl.cnf".source = yunohost + "/share/yunohost/templates/ssl/openssl.cnf";
      # init
      "yunohost/yunohost-config/ssl/yunoCA/serial".source = caCertsDrv + "/serial";
      "yunohost/yunohost-config/ssl/yunoCA/index.txt".source = pkgs.writeText "index.txt" "";
      "yunohost/yunohost-config/ssl/yunoCA/ca/cacert.pem".source = caCertsDrv + "/ca/cacert.pem";
      "yunohost/yunohost-config/ssl/yunoCA/ca/cakey.pem".source = caCertsDrv + "/ca/cakey.pem";
      "yunohost/certs/yunohost.org/ca.pem".source = caCertsDrv + "/ca/cacert.pem";
      "ssl/certs/ca-yunohost_crt.pem".source = caCertsDrv + "/ca/cacert.pem";
      "yunohost/yunohost-config/ssl/yunoCA/certs/yunohost_csr.pem".source = caCertsDrv + "/certs/yunohost_csr.pem";
      "yunohost/yunohost-config/ssl/yunoCA/certs/yunohost_key.pem".source = caCertsDrv + "/certs/yunohost_key.pem";
      "yunohost/yunohost-config/ssl/yunoCA/certs/yunohost_crt.pem".source = caCertsDrv + "/certs/yunohost_crt.pem";
      "yunohost/certs/yunohost.org/key.pem".source = caCertsDrv + "/certs/yunohost_key.pem";
      "yunohost/certs/yunohost.org/crt.pem".source = caCertsDrv + "/certs/yunohost_crt.pem";
      "ssl/certs/yunohost_crt.pem".source = caCertsDrv + "/certs/yunohost_crt.pem";
      "ssl/private/yunohost_key.pem".source = caCertsDrv + "/certs/yunohost_key.pem";
    };

    systemd.tmpfiles.rules = [
      "d /etc/cron.d         0755 root root -"
      "d /etc/yunohost/apps  0755 root root -"
    ];

    systemd.packages = [ yunohost ];
    systemd.services.yunohost-api.enable = true;
    systemd.services.yunohost-firewall.enable = true;

    services.postfix = {
      /*
      postfix postfix/main_mailer_type        select Internet Site
      postfix postfix/mailname string /etc/mailname
      */
      enable = true;
    };

    services.dovecot2 = {
      enable = true;
      # protocols = [ "imap" "sieve" ''{% if pop3_enabled == "True" %}pop3{% endif %}'' ];
      # sslServerCert = "/etc/yunohost/certs/{{ main_domain }}/crt.pem";
      sslServerCert = "/etc/yunohost/certs/yunohost.org/crt.pem";
      # sslServerKey = "/etc/yunohost/certs/{{ main_domain }}/key.pem";
      sslServerKey = "/etc/yunohost/certs/yunohost.org/key.pem";
      mailUser = "500";
      mailGroup = "8";
      mailLocation = "maildir:/var/mail/%n";
      enableQuota = true;
      # extraConfig = ''
      #   !include yunohost.d/pre-ext.conf
      #   listen = *, ::
      #   auth_mechanisms = plain login
      #   mail_home = /var/mail/%n

      #   ssl = required
      #   ssl_min_protocol = TLSv1.2
      #   ssl_cipher_list = ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
      #   ssl_prefer_server_ciphers = no

      #   passdb {
      #     args = /etc/dovecot/dovecot-ldap.conf
      #     driver = ldap
      #   }

      #   userdb {
      #     args = /etc/dovecot/dovecot-ldap.conf
      #     driver = ldap
      #   }

      #   protocol imap {
      #     imap_client_workarounds =
      #     mail_plugins = $mail_plugins imap_quota antispam
      #   }


      #   protocol lda {
      #     auth_socket_path = /var/run/dovecot/auth-master
      #     mail_plugins = quota sieve
      #     postmaster_address = postmaster@{{ main_domain }}
      #   }

      #   protocol sieve {
      #   }

      #   service auth {
      #     unix_listener /var/spool/postfix/private/auth {
      #       group = postfix
      #       mode = 0660
      #       user = postfix
      #     }
      #     unix_listener auth-master {
      #       group = mail
      #       mode = 0660
      #       user = vmail
      #     }
      #   }

      #   service quota-warning {
      #     executable = script /usr/bin/quota-warning.sh
      #     user = vmail
      #     unix_listener quota-warning {
      #     }
      #   }

      #   plugin {
      #     sieve = /var/mail/sievescript/%n/.dovecot.sieve
      #     sieve_dir = /var/mail/sievescript/%n/scripts/
      #     sieve_before = /etc/dovecot/global_script/
      #   }

      #   plugin {
      #     antispam_debug_target = syslog
      #     antispam_verbose_debug = 0
      #     antispam_backend = pipe
      #     antispam_spam = Junk;SPAM
      #     antispam_trash = Trash
      #     antispam_pipe_program = /usr/bin/rspamc
      #     antispam_pipe_program_args = -h;localhost:11334;-P;q1
      #     antispam_pipe_program_spam_arg = learn_spam
      #     antispam_pipe_program_notspam_arg = learn_ham
      #   }

      #   plugin {
      #     quota = maildir:User quota
      #     quota_rule2 = SPAM:ignore
      #     quota_rule3 = Trash:ignore
      #   }

      #   plugin {
      #     quota_warning = storage=95%% quota-warning 95 %u
      #     quota_warning2 = storage=80%% quota-warning 80 %u
      #     quota_warning3 = -storage=100%% quota-warning below %u # user is no longer over quota
      #   }

      #   !include yunohost.d/post-ext.conf
      # '';
    };

    services.mysql = {
      /*
      mariadb-server-10.1 mysql-server/root_password password yunohost
      mariadb-server-10.1 mysql-server/root_password_again password yunohost
      */
      enable = true;
      package = pkgs.mariadb;
    };

    services.nginx.enable = true;
    services.metronome.enable = true;

    services.openldap = rec {
      /*
      slapd slapd/password1 password yunohost
      slapd slapd/password2 password yunohost
      slapd slapd/domain    string yunohost.org
      slapd shared/organization     string yunohost.org
      slapd	slapd/allow_ldap_v2	boolean	false
      slapd	slapd/invalid_config	boolean	true
      slapd	slapd/backend	select	MDB
      */
      enable = true;
      suffix = "dc=yunohost,dc=org";
      # rootdn = "cn=admin,${suffix}";
      rootdn = "cn=config,${suffix}";
      rootpw = "yunohost";
      database = "mdb";

      declarativeContents = builtins.readFile ./yunohost/openldap.ldif;
    };

    users.ldap = rec {
      enable = true;
      server = "ldap://localhost/";
      base = "dc=yunohost,dc=org";

      daemon = {
        /*
        nslcd	nslcd/ldap-bindpw	password
        nslcd	nslcd/ldap-starttls	boolean	false
        nslcd	nslcd/ldap-reqcert	select
        nslcd	nslcd/ldap-uris	string	ldap://localhost/
        nslcd	nslcd/ldap-binddn	string
        nslcd	nslcd/ldap-base	string	dc=yunohost,dc=org
        libnss-ldapd    libnss-ldapd/nsswitch multiselect group, passwd, shadow
        */
        enable = true;
        rootpwmoddn = "cn=config,${base}";
        rootpwmodpwFile = builtins.toString (pkgs.writeText "ldap-pwd" "yunohost");
      };

      bind = {
        passwordFile = builtins.toString (pkgs.writeText "ldap-pwd" "yunohost");
      };
    };

    services.postsrsd = {
      /*
      postsrsd postsrsd/domain string yunohost.org
      */
      enable = true;
    };

    services.openssh = {
      enable = true;
      permitRootLogin = "no";
      ports = [ 22 ];
    };

    services.fail2ban.enable = true;

    services.avahi = {
      enable = true;
      hostName = "yunohost";
      domainName = "local";
      ipv4 = true;
      ipv6 = true;

      wideArea = true;

      extraConfig = ''
        # [server]
        # ratelimit-interval-usec=1000000
        # ratelimit-burst=1000

        [rlimits]
        rlimit-core=0
        rlimit-data=4194304
        rlimit-fsize=0
        rlimit-nofile=768
        rlimit-stack=4194304
        rlimit-nproc=3
      '';
    };

    # DNS resolution
    # services.dnsmasq = {
    #   enable = true;
    # };

  };
}
