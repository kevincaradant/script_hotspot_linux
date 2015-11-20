#!/bin/bash

### install hostapd
apt-get -y install hostapd

### it should not start automatically on boot
update-rc.d hostapd disable

### get ssid and password
ssid=$(hostname --short)
read -p "The name of your hosted network (SSID) [$ssid]: " input
ssid=${input:-$ssid}
password='1234567890'
read -p "The password of your hosted network [$password]: " input
password=${input:-$password}
network='wlan0'
read -p "Type network to be share : [$network]" input
network=${input:-$network}
networkShare='eth0'
read -p "Type network which is the source : [$networkShare]" input
networkShare=${input:-$networkShare}
bridge='br0'
read -p "Name of the bridge : [$bridge]" input
bridge=${input:-$bridge}

### get wifi interface
rfkill unblock wifi   # enable wifi in case it is somehow disabled (thanks to Darrin Wolf for this tip)
wifi_interface=$network
### create /etc/hostapd/hostapd.conf
cat <<EOF > /etc/hostapd/hostapd.conf
interface=$wifi_interface
bridge=$bridge
ssid=$ssid
hw_mode=g
channel=6
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$password
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
macaddr_acl=0
EOF

### modify /etc/default/hostapd
cp /etc/default/hostapd /etc/default/hostapd.bak

sed -i /etc/default/hostapd \
    -e '/DAEMON_CONF=/c DAEMON_CONF="/etc/hostapd/hostapd.conf"'
service hostapd start

cat <<EOF > /etc/init.d/wifi_access_point
#!/bin/bash

function stop_wifi_ap {
    ### stop services dhcpd and hostapd
    service hostapd stop

    ### remove the static IP from the wifi interface
    if grep -q 'iface $bridge inet dhcp' /etc/network/interfaces
    then
        sed -i.bak '/#wired adapter/d' /etc/network/interfaces
        sed -i.bak '/iface $networkShare inet dhcp/d' /etc/network/interfaces
        sed -i.bak '/#bridge/d' /etc/network/interfaces
        sed -i.bak '/auto $bridge/d' /etc/network/interfaces
        sed -i.bak '/iface $bridge inet dhcp/d' /etc/network/interfaces
        sed -i.bak '/bridge_ports $networkShare $wifi_interface/d' /etc/network/interfaces
    fi

    ### restart network manager to takeover wifi management
    service network-manager restart
}

function start_wifi_ap {
    stop_wifi_ap

    ### protect the static IP from network-manger restart
    echo '#wired adapter' >> /etc/network/interfaces
    echo 'iface $networkShare inet dhcp' >> /etc/network/interfaces
    echo '#bridge' >> /etc/network/interfaces
    echo 'auto $bridge' >> /etc/network/interfaces
    echo 'iface $bridge inet dhcp' >> /etc/network/interfaces
    echo 'bridge_ports $networkShare $wifi_interface' >> /etc/network/interfaces

    ### enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    ### start services dhcpd and hostapd
    systemctl daemon-reload
    sudo service network-manager restart
    service hostapd start
}

### start/stop wifi access point
case "\$1" in
    start) start_wifi_ap ;;
    stop)  stop_wifi_ap  ;;
esac
EOF


cat <<EOF >> ~/.bashrc 
alias start_hotspot='sudo service wifi_access_point start'
alias stop_hotspot='sudo service wifi_access_point stop'
EOF

chmod +x /etc/init.d/wifi_access_point

### make sure that it is stopped on boot
sed -i /etc/rc.local \
    -e '/service wifi_access_point stop/ d'
sed -i /etc/rc.local \
    -e '/^exit/ i service wifi_access_point stop'
systemctl daemon-reload
service wifi_access_point start
### display usage message
echo "
======================================

Wifi Access Point installed.

You can start and stop it with:
    service wifi_access_point start
    service wifi_access_point stop

NB : REBOOT AS SOON AS POSSIBLE TO USE CORRECTLY THE HOTSPOT :) 
"