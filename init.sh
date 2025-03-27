#!/bin/sh

: "${WG_CONFIG:?Environment variable WG_CONFIG must be set}"

echo "Starting WireGuard"


# Copied from wg-quick
echo "Configuring the wg0 interface"
ip link add wg0 type wireguard
wg setconf wg0 $WG_CONFIG
ip link set mtu 65440 up dev wg0
wg set wg0 fwmark 51820

echo "Configuring IPv6 routes"
ip -6 route add ::/0 dev wg0 table 51820
ip -6 rule add not fwmark 51820 table 51820
ip -6 rule add table main suppress_prefixlength 0

echo "Configuring IPv4 routes"
ip -4 route add 0.0.0.0/0 dev wg0 table 51820
ip -4 rule add not fwmark 51820 table 51820
ip -4 rule add table main suppress_prefixlength 0

WG_ENDPOINT=$(cat $WG_CONFIG | grep "^Endpoint =" | awk '{print $3}')
WG_ENDPOINT_IP=$(echo $WG_ENDPOINT | grep -oE '^(.+?)[:]' | sed s/[][]//g | sed s/.$//)
WG_ENDPOINT_PORT=$(echo $WG_ENDPOINT | sed -E s/.+://)

# Check if IPv4 or IPv6 by filtering for colon
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