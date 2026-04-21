# agenix recipient map. This file is consumed by the `agenix` CLI
# when encrypting / rekeying *.age files — it tells agenix which
# public keys can decrypt each secret.
#
# It is NOT imported by NixOS. It's a data file for the CLI. The
# runtime side (age.secrets.<name>.file = ./foo.age) lives in the
# host config wherever a secret is actually needed.
#
# ---- populating this file post-install -----------------------------
# After the first boot of `wammu`, grab the host's ed25519 SSH key:
#
#   ssh wammu 'cat /etc/ssh/ssh_host_ed25519_key.pub'
#
# and paste into `wammu-host` below. The user key is whatever local
# SSH key you use to encrypt secrets — typically ~/.ssh/id_ed25519.pub.
#
# ---- adding a secret -----------------------------------------------
# 1. Populate the public keys below (first time only).
# 2. Add an entry to the `secrets` attrset: "<name>.age".publicKeys = all
# 3. `cd secrets && agenix -e <name>.age` and paste the plaintext.
# 4. In the module that consumes the secret, set
#      age.secrets.<name>.file = ../../secrets/<name>.age
#    and reference `config.age.secrets.<name>.path` at runtime.
# 5. Commit the *.age file (ciphertext is safe to commit).

let
  # Placeholders — replace with real pubkeys once the host is up.
  # Left intentionally null-ish so `agenix -e` fails loudly if anyone
  # tries to encrypt before the recipient map is populated.
  wammu-host = null;
  wammu-user = null;

  all = builtins.filter (k: k != null) [ wammu-host wammu-user ];
in
{
  # Example — uncomment and add the .age file once there's a real
  # secret to encrypt. Until then, keep this empty so `nixos-rebuild`
  # stays green with zero secrets.
  #
  # "tailscale-authkey.age".publicKeys = all;
  # "wifi-home.age".publicKeys         = all;
}
