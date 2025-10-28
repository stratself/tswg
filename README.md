# tswg

Daisy chain a Tailscale with a WireGuard tunnel from another VPN provider, to create a VPN exit node for your tailnet.

Tested working on rootless Podman. Although this is highly experimental, so please open issues to correct any of my footguns that you can find.

## Features

- Runnable in non-root containers

  - Only `NET_ADMIN` is required

  - `wg-quick` with small fixes to run rootlessly

- [containerboot](https://pkg.go.dev/tailscale.com/cmd/containerboot) compliant

- IPv4 and IPv6 ip rules included

- Other tailnet nodes and MagicDNS natively accessible (via ping,curl,etc). Good for running with your own Pi-Hole.

- Custom endpoints to not be routed through the WireGuard interface.

## Howto

See `docker-compose.yml` for the main configuration values. Most of the explanations are commented in there.

1. Clone the repo and optionally build the container

2. Fetch a WireGuard file from your VPN provider and format it to look like `./example.wg0.conf`. The main tweak is to remove the DNS field.

3. Configure `docker-compose.yml` to your own tastes and bring it up

## Environment variables

Specific env vars for this image:

| Name                     | Default    | Description                                                                                                                                                                    |
| ------------------------ | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `WG_CONFIG`              | `none`     | Path to your WireGuard config file                                                                                                                                             |
| `HOLEPUNCH_ENDPOINTS`    | `none`     | (Optional) Custom endpoints in `IP:Port` format that will not go through the WireGuard tunnel. Useful for connecting to Headscale if set. Only IPv4 and TCP traffic is supported for now. |

These env vars are changed from [Tailscale defaults](https://tailscale.com/kb/1282/docker):

| Name                     | Default    | Description                 |
| ------------------------ | ---------- | --------------------------- |
| `TS_USERSPACE`           | `false`    | Changed to false by default |
| `TS_DEBUG_FIREWALL_MODE` | `nftables` | Force use of new nftables instead of auto mode   |

## Security and other issues

- Unlike Tailscale's Mullvad exit node, this container does not have `IsJailed` and `IsWireguardOnly` functionality toggled on for traffic restrictions. Please control traffic flows using ACL or grants.

- This image provides a feature akin to [multihop](https://www.procustodibus.com/blog/2022/06/multi-hop-wireguard/#internet-gateway-as-a-spoke), whereby the first hop is controlled at a location that you can host. Therefore, the speed is reduced, and can significantly slow down if your VPN endpoint is far away from your tswg instance.

    ```mermaid
    graph LR
      client --> tswg[tswg in us] --> vpn1[vpn in canada]
      client --> tswg[tswg in us] ---> vpn2[vpn in germany]
      client --> tswg[tswg in us] ----> vpn3[vpn in japan]
    ```

- This image provides an alternative to headscale's current (lack of) [WireGuard only peers](https://github.com/juanfont/headscale/issues/1545) implementation

## Alternatives

- [Gluetun](https://github.com/qdm12/gluetun/) + Tailscale has strict firewalls that conflicts with Tailscale running on non-userspace mode. If someone gets theirs working, please share (probably some postrouting rules that I haven't looked into).
- [Wireproxy](https://github.com/whyvl/wireproxy) + [tun2socks](https://github.com/xjasonlyu/tun2socks/) kind of worked but segfaults every 5 minutes for some reason.
