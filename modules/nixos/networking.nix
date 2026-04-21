{ ... }:

{
  networking = {
    networkmanager.enable = true;

    firewall = {
      enable = true;
      # Tailscale: trust the tailscale interface entirely and open its UDP
      # listen port so peers can reach you over the tailnet.
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ 41641 ];
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    # useRoutingFeatures = "client";  # uncomment to accept subnet routes
  };

  # resolvectl-backed systemd-resolved plays nicer with tailscale MagicDNS
  # than the default dnsmasq.
  services.resolved.enable = true;
}
