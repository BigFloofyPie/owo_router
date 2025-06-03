# owo_router

This repository provides a helper script to configure a Linux host as a
Wi-Fi access point (`wlan1`) that offers a SOCKS5 proxy using
`dante-server`.

## Usage

1. Clone the repository and run `setup_socks5_ap.sh` with root privileges.
   The script installs required packages and configures `hostapd`,
   `dnsmasq`, and `dante-server`. When started without arguments it
   displays a small interactive menu.

```bash
sudo ./setup_socks5_ap.sh
```

2. Adjust the variables `INTERFACE_WIFI` and `INTERFACE_INTERNET` inside
   the script or export them before running to match your wireless and
   internet-facing interfaces.

Clients connecting to the Wi-Fi network will be able to use the SOCKS5
proxy running on port `1080` of the host.
