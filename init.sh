#!/bin/sh

: "${TSWG_WGCONF:-${WG_CONFIG:?Environment variable TSWG_WGCONF must be set}}"
if [ -z $TSWG_WGCONF ]; then TSWG_WGCONF=$WG_CONFIG; fi

echo "Starting WireGuard"

# Copied from wg-quick
echo "Using wg-quick to set up WireGuard tunnel"
wg-quick up $TSWG_WGCONF

WG_ENDPOINT=$(cat $TSWG_WGCONF | grep "^Endpoint =" | awk '{print $3}')
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

# Holepunch comma-separated endpoints

if [[ -z ${TSWG_HOLEPUNCH_ENDPOINTS:-${HOLEPUNCH_ENDPOINTS}} ]]; then
        echo "WARNING: \$TSWG_HOLEPUNCH_ENDPOINTS are not set"
        echo "This may disrupt connectivity to your Headscale instance"
    else
        for ENDPOINT in $(echo $TSWG_HOLEPUNCH_ENDPOINTS | sed "s/,/ /g"); 
            do
                ENDPOINT_IPADDR=$(echo $ENDPOINT | grep -oE '^(.+?)[:]' | sed s/[][]//g | sed s/.$//)
                ENDPOINT_PORT=$(echo $ENDPOINT | sed -E s/.+://)
                echo "Hole-punching $ENDPOINT_IPADDR:$ENDPOINT_PORT"        
                ip -4 route add default dev eth0 table 80
                ip -4 rule add from all to $ENDPOINT_IPADDR ipproto tcp dport $ENDPOINT_PORT lookup 80
            done
fi

echo "Starting tailscale"
/usr/local/bin/containerboot &

# Sockd stuff
if [ "${TSWG_SOCKD_ENABLED}" == "true" ]; then
    
    echo "SOCKS5 enabled"
    export TSWG_DANTE_FILE=${TSWG_SOCKD_FILE};
    
    if [ -n $TSWG_DANTE_FILE ]; then

        cp /etc/sockd.conf /tmp/sockd.conf.tmp
        export TSWG_DANTE_FILE="/tmp/sockd.conf.tmp"

        TSWG_DANTE_PORT=${TSWG_SOCKD_PORT:-"1080"}
        sed -i s/TSWG_DANTE_PORT/${TSWG_DANTE_PORT}/g $TSWG_DANTE_FILE

        TSWG_DANTE_EXTERNAL=$(basename ${TSWG_WGCONF%.conf})
        sed -i s/TSWG_DANTE_EXTERNAL/${TSWG_DANTE_EXTERNAL}/g $TSWG_DANTE_FILE
    
    fi;

    echo "Starting SOCKS5 proxy"
    sleep ${TSWG_SOCKD_TIMEIN:-3}
    sockd -f ${TSWG_DANTE_FILE}
fi

# Avoid script from exiting
while : ; do sleep 1 ; done ;