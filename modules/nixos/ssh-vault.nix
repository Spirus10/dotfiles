{ pkgs, ... }:

let
  user = "wammu";
  group = "users";
  home = "/home/${user}";
  mountDir = "${home}/.ssh/ssh_keys_mnt";
  imgFile = "${home}/.ssh/ssh_keys.img";
  mapperName = "ssh_keys";
in
{
  # Nix owns the scaffolding, not the encrypted payload. Keep
  # ssh_keys.img out of the store and restore it onto the host manually.
  systemd.tmpfiles.rules = [
    "d ${home}/.ssh 0700 ${user} ${group} -"
    "d ${mountDir} 0700 ${user} ${group} -"
  ];

  systemd.services.ssh-keys-vault = {
    description = "Open and mount encrypted SSH key vault";
    after = [ "local-fs.target" ];

    path = with pkgs; [
      coreutils
      cryptsetup
      findutils
      util-linux
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      test -f ${imgFile}

      cryptsetup luksOpen ${imgFile} ${mapperName}
      mount /dev/mapper/${mapperName} ${mountDir}
      chown -R ${user}:${group} ${mountDir}
      chmod 700 ${mountDir}
      find ${mountDir} -type f -exec chmod 600 {} +
    '';

    preStop = ''
      umount ${mountDir}
      cryptsetup luksClose ${mapperName}
    '';
  };
}
