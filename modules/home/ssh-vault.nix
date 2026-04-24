{ config, pkgs, ... }:

let
  mountDir = "${config.home.homeDirectory}/.ssh/ssh_keys_mnt";
  sshVault = pkgs.writeShellScriptBin "ssh-vault" ''
    set -euo pipefail

    usage() {
      echo "Usage: ssh-vault [open|close|status]" >&2
    }

    case "''${1:-}" in
      open)
        sudo ${pkgs.systemd}/bin/systemctl start ssh-keys-vault.service
        ${pkgs.systemd}/bin/systemctl --user start ssh-keys-agent.service
        ;;
      close)
        ${pkgs.systemd}/bin/systemctl --user stop ssh-keys-agent.service || true
        sudo ${pkgs.systemd}/bin/systemctl stop ssh-keys-vault.service
        ;;
      status)
        vault_status=0
        agent_status=0

        sudo ${pkgs.systemd}/bin/systemctl status ssh-keys-vault.service || vault_status=$?
        ${pkgs.systemd}/bin/systemctl --user status ssh-keys-agent.service || agent_status=$?

        if [ "$vault_status" -ne 0 ]; then
          exit "$vault_status"
        fi
        exit "$agent_status"
        ;;
      *)
        usage
        exit 2
        ;;
    esac
  '';
in
{
  home.packages = [ sshVault ];

  services.ssh-agent.enable = true;

  systemd.user.services.ssh-keys-agent = {
    Unit = {
      Description = "Load mounted SSH vault keys into ssh-agent";
      After = [ "ssh-agent.service" ];
      Wants = [ "ssh-agent.service" ];
    };

    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent";

      ExecStart = pkgs.writeShellScript "ssh-keys-agent-start" ''
        set -euo pipefail

        shopt -s nullglob
        for key in ${mountDir}/*; do
          case "$key" in
            *.pub) ;;
            *) ${pkgs.openssh}/bin/ssh-add "$key" 2>/dev/null || true ;;
          esac
        done
      '';

      ExecStop = pkgs.writeShellScript "ssh-keys-agent-stop" ''
        set -euo pipefail

        shopt -s nullglob
        for key in ${mountDir}/*; do
          case "$key" in
            *.pub) ;;
            *) ${pkgs.openssh}/bin/ssh-add -d "$key" 2>/dev/null || true ;;
          esac
        done
      '';
    };
  };
}
