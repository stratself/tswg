#!/bin/sh

: "${WG_CONFIG:?Environment variable WG_CONFIG must be set}"

echo "Starting WireGuard"


# Copied from wg-quick
echo "Using wg-quick to set up WireGuard tunnel"
wg-quick up $WG_CONFIG

WG_ENDPOINT=$(cat $WG_CONFIG | grep "^Endpoint =" | awk '{print $3}')
WG_ENDPOINT_IP=$(echo $WG_ENDPOINT | grep -oE '^(.+?)[:]' | sed s/[][]//g | sed s/.$//)
WG_ENDPOINT_PORT=$(echo $WG_ENDPOINT | sed -E s/.+://)

# Hole-punching IPv4 endpoints in order to connect to upstream WireGuard itself via main interface

if  [ $( echo $WG_ENDPOINT_IP | grep ':' ) ]
    then 
        echo $WG_ENDPOINT_IP
        echo "Endpoint is IPv6, hole-punching not necessary"
    else
        echo "Holepunching UDP traffic to WireGuard endpoint ($WG_ENDPOINT_IP:$WG_ENDPOINT_PORT) via main interface"
        ip -4 route add default dev eth0 table 80
        ip -4 rule add from all to $WG_ENDPOINT_IP iif wg0 ipproto udp dport $WG_ENDPOINT_PORT lookup 80
        ip -4 rule add from all to $WG_ENDPOINT_IP iif lo ipproto udp dport $WG_ENDPOINT_PORT lookup 80
fi

# Holepunch selected endpoints

if [[ -z $HOLEPUNCH_ENDPOINTS ]]; then
        echo "WARNING: \$HOLEPUNCH_ENDPOINTS are not set"
        echo "This may disrupt connectivity to your Headscale instance"
    else
        for ENDPOINT in $(echo $HOLEPUNCH_ENDPOINTS | sed "s/,/ /g"); 
            do
                ENDPOINT_IPADDR=$(echo $ENDPOINT | grep -oE '^(.+?)[:]' | sed s/[][]//g | sed s/.$//)
                ENDPOINT_PORT=$(echo $ENDPOINT | sed -E s/.+://)
                echo "Hole-punching $ENDPOINT_IPADDR:$ENDPOINT_PORT"        
                ip -4 route add default dev eth0 table 80
                ip -4 rule add from all to $ENDPOINT_IPADDR ipproto tcp dport $ENDPOINT_PORT lookup 80
            done
fi

echo "Starting tailscale"
/usr/local/bin/containerboot