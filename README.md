# tswg

Daisy chain a Tailscale with a WireGuard tunnel from another VPN provider, to create a VPN exit node for your tailnet.

Tested working on rootless Podman. Please open issues to correct any footguns you found.

## Features

- Runnable in non-root containers

  - Only `NET_ADMIN` is required

  - `wg-quick` with small fixes to run rootlessly

- [containerboot](https://pkg.go.dev/tailscale.com/cmd/containerboot) compliant

- IPv4 and IPv6 ip rules included

- Other tailnet nodes and MagicDNS natively accessible (via ping,curl,etc). Good for running with your own Pi-Hole.

- Custom endpoints to not be routed through the WireGuard interface.

## Howto

1. Fetch a WireGuard file from your VPN provider and format it to look like `./example.wg0.conf`. The main tweak is to remove the DNS field.

2. Configure `docker-compose.yml` to your own tastes and bring it up. Most of the explanations and config values are commented in there.


## Environment variables

Specific env vars for this image:

| Name                     | Default    | Description                                                                                                                                                                    |
| ------------------------ | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `TSWG_WGCONF`              | `none`     | Path to your WireGuard config file                                                                                                                                             |
| `TSWG_HOLEPUNCH_ENDPOINTS`    | `none`     | (Optional) Custom endpoints in `IPv4:Port` format that bypass the WireGuard tunnel. Useful for connecting to your own Headscale. |

The legacy variables `WG_CONFIG` and `HOLEPUNCH_ENDPOINTS` in versions prior to `v1.92.4` are also supported as fallback variables.


These env vars are changed from [Tailscale defaults](https://tailscale.com/kb/1282/docker):

| Name                     | Default    | Description                 |
| ------------------------ | ---------- | --------------------------- |
| `TS_USERSPACE`           | `false`    | Changed to false by default |
| `TS_DEBUG_FIREWALL_MODE` | `nftables` | Force use of new nftables instead of auto mode   |

Other Tailscale [env vars for Docker](https://tailscale.com/kb/1282/docker) should also work.

### SOCKS5 proxy

> [!IMPORTANT]
> This feature is only available in the `main` image branch right now

You can enable a SOCKS5 proxy server powered by [Dante](https://www.inet.no/dante/). This is a replacement for Tailscale's embedded proxy (`TS_SOCKS5_PROXY`), which doesn't work for some [reason](https://github.com/stratself/tswg/issues/4).

It has the following env vars:

| Name                 | Default | Description                                                                                      |
| -------------------- | ------- | ------------------------------------------------------------------------------------------------ |
| `TSWG_SOCKD_ENABLED` |         | Set to `true` to enable sockd                                                                    |
| `TSWG_SOCKD_PORT`    | `1080`  | Port number to expose tswg on                                                                    |
| `TSWG_SOCKD_FILE`    |         | Mount your own `sockd.conf` file for advanced usage. `TSWG_SOCKD_PORT` will be ignored |
| `TSWG_SOCKD_TIMEIN`  | `3`     | Seconds to wait until starting the socks daemon                                                  |

The default `sockd.conf` file is at `/etc/sockd.conf` and will get copied to `/tmp/sockd.conf.tmp` before enabling. For more information on the config file, check out its [man page](https://man.archlinux.org/man/sockd.conf.5.en).


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
- [Tailguard](https://github.com/juhovh/tailguard) seems to be the most similar candidate, though it can also be used for general WireGuard routing.
