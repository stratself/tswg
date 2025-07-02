# tswg

Run a Tailscale exit node alongside a WireGuard tunnel from another VPN provider. Tested working on rootless Podman.

**This is highly experimental**, I'm a noob etc... please open issues to correct any of my footguns that you can find.

## Features

- Runnable in non-root containers

  - Only `NET_ADMIN` is required

  - `wg-quick` with small fixes to run rootlessly

- containerboot compliant

- IPv4 and IPv6 ip rules included

- Other tailnet nodes and MagicDNS natively accessible (via ping,curl,etc). Good for running with your own Pi-Hole.

- Custom endpoints to not be routed through the WireGuard interface.

## Howto

Requires some docker-compose knowledge

1. Clone the repo and optionally build the container

2. Provide your own WireGuard config file from your commercial VPN provider. Edit it to look like `example.wg0.conf`:
   - `wg-quick` variables like `Address` or `PreDown/PostUp` are **not supported**, as they'll error out whilst running `wg setconf`

3. Configure `docker-compose.yml` to your own tastes and bring it up. Most of the explanations are commented in there.

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

## Alternatives

- [Gluetun](https://github.com/qdm12/gluetun/) + Tailscale has strict firewalls that conflicts with Tailscale running on non-userspace mode. If someone gets theirs working, please share (probably some postrouting rules that I haven't looked into).
- [Wireproxy](https://github.com/whyvl/wireproxy) + [tun2socks](https://github.com/xjasonlyu/tun2socks/) kind of worked but segfaults every 5 minutes for some reason.