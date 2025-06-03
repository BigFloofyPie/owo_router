#!/usr/bin/env bash
# Minimal helper to configure and manage a Wi-Fi access point on
# `wlan1` with a SOCKS5 proxy. All commands require root privileges.

set -e

INTERFACE_WIFI=${INTERFACE_WIFI:-wlan1}
INTERFACE_INTERNET=${INTERFACE_INTERNET:-eth0}

HOSTAPD_CONF=/etc/hostapd/hostapd.conf
DNSMASQ_CONF=/etc/dnsmasq.conf
DANTE_CONF=/etc/danted.conf

setup_ap() {
    echo "Configuring access point for $INTERFACE_WIFI"
    # Uncomment if packages are missing
    # apt-get update && apt-get install -y hostapd dnsmasq dante-server

    cat <<EOM > "$HOSTAPD_CONF"
interface=$INTERFACE_WIFI
driver=nl80211
ssid=OWO_Router
hw_mode=g
channel=7
wmm_enabled=1
auth_algs=1
wpa=2
wpa_passphrase=supersecret
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOM

    cat <<EOM > "$DNSMASQ_CONF"
interface=$INTERFACE_WIFI
dhcp-range=10.0.0.10,10.0.0.50,12h
EOM

    ip addr add 10.0.0.1/24 dev "$INTERFACE_WIFI" || true
    sysctl -w net.ipv4.ip_forward=1
    iptables -t nat -A POSTROUTING -o "$INTERFACE_INTERNET" -j MASQUERADE

    cat <<EOM > "$DANTE_CONF"
logoutput: /var/log/danted.log
internal: $INTERFACE_WIFI port = 1080
external: $INTERFACE_INTERNET
method: username none
user.notprivileged: nobody
client pass {
        from: 10.0.0.0/24 to: 0.0.0.0/0
        log: connect disconnect
}
pass {
        from: 10.0.0.0/24 to: 0.0.0.0/0
        protocol: tcp udp
}
EOM
}

start_services() {
    systemctl restart hostapd
    systemctl restart dnsmasq
    systemctl restart danted
}

stop_services() {
    systemctl stop hostapd
    systemctl stop dnsmasq
    systemctl stop danted
}

status_services() {
    systemctl status hostapd dnsmasq danted
}

menu() {
    while true; do
        echo "\n=== Minimal AP Manager ==="
        echo "1) Setup"
        echo "2) Start"
        echo "3) Stop"
        echo "4) Status"
        echo "5) Quit"
        read -rp "Select: " choice
        case $choice in
            1) setup_ap ;;
            2) start_services ;;
            3) stop_services ;;
            4) status_services ;;
            5) exit 0 ;;
            *) echo "Invalid option" ;;
        esac
    done
}

case $1 in
    setup)  setup_ap ;;
    start)  start_services ;;
    stop)   stop_services ;;
    status) status_services ;;
    menu|"") menu ;;
    *) echo "Usage: $0 [setup|start|stop|status|menu]"; exit 1 ;;
 esac

echo "Done"
