#!/bin/bash

# Nama pengguna GitHub untuk pengambilan kebenaran dari repo
GitUser="melody97rain"

# Ambil IP awam sekali sahaja
MYIP=$(curl -sS ipv4.icanhazip.com)

echo -e "\e[32mloading...\e[0m"
clear

# Tetapan pemboleh ubah akaun percubaan
Login="trial$(</dev/urandom tr -dc X-Z0-9 | head -c4)"
Pass="1"
masaaktif=1  # Tempoh sah akaun (hari)

echo "Ping Host"
echo "Check Access..."
sleep 0.5
echo "Permission Accepted"
clear
sleep 0.5
echo "Create Account: $Login"
sleep 0.5
echo "Setting Password: $Pass"
sleep 0.5
clear

# Buat akaun dengan tempoh tamat yang ditetapkan
/usr/sbin/useradd -e $(date -d "+$masaaktif days" +"%Y-%m-%d") -s /bin/false -M $Login

# Tetapkan kata laluan akaun
echo -e "$Pass\n$Pass" | passwd $Login &> /dev/null

# Ambil maklumat tamat akaun
exp=$(chage -l $Login | grep "Account expires" | awk -F": " '{print $2}')

# Dapatkan domain dan port dari konfigurasi sedia ada
domain=$(cat /usr/local/etc/xray/domain 2>/dev/null)
if [[ -z "$domain" ]]; then
    domain=$MYIP
fi

ssl_port=$(grep -w "Stunnel4" ~/log-install.txt | cut -d: -f2 | xargs)
squid_port=$(grep -w "Squid" ~/log-install.txt | cut -d: -f2 | xargs)
ovpn_tcp=$(netstat -nlpt 2>/dev/null | grep -i openvpn | grep -w '0.0.0.0' | awk '{print $4}' | cut -d: -f2 | head -1)
ovpn_udp=$(netstat -nlpu 2>/dev/null | grep -i openvpn | grep -w '0.0.0.0' | awk '{print $4}' | cut -d: -f2 | head -1)
ovpn_ssl=$(grep -w "OpenVPN SSL" ~/log-install.txt | cut -d: -f2 | xargs)
ovpn_ohp=$(grep -w "OHP OpenVPN" ~/log-install.txt | cut -d: -f2 | xargs)
ohp_ssh=$(grep -w "OHP SSH" ~/log-install.txt | cut -d: -f2 | xargs)
ohp_dropbear=$(grep -w "OHP Dropbear" ~/log-install.txt | cut -d: -f2 | xargs)
ws_ssh_http=$(grep -w "Websocket SSH(HTTP)" ~/log-install.txt | cut -d: -f2 | xargs)
ws_ssl_https=$(grep -w "Websocket SSL(HTTPS)" ~/log-install.txt | cut -d: -f2 | xargs)
ws_openvpn=$(grep -w "Websocket OpenVPN" ~/log-install.txt | cut -d: -f2 | xargs)
nsdomain=$(cat /root/nsdomain 2>/dev/null || echo "-")
pubkey=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "-")

# Paparkan info akaun
echo -e ""
echo -e "Premium Trial Account SSH & OpenVPN"
echo -e "=================================="
echo -e "Username       : $Login"
echo -e "Password       : $Pass"
echo -e "Expires On     : $exp"
echo -e "Domain         : $domain"
echo -e "Name Server(NS): $nsdomain"
echo -e "Pubkey         : $pubkey"
echo -e "IP/Host        : $MYIP"
echo -e "OpenSSH        : 22"
echo -e "Dropbear       : 143, 109"
echo -e "SSL/TLS        : $ssl_port"
echo -e "SlowDNS        : 22,80,443,53,5300"
echo -e "SSH-UDP        : 1-65535"
echo -e "WS SSH(HTTP)   : $ws_ssh_http"
echo -e "WS SSL(HTTPS)  : $ws_ssl_https"
echo -e "WS OpenVPN(HTTP): $ws_openvpn"
echo -e "OHP Dropbear   : $ohp_dropbear"
echo -e "OHP OpenSSH    : $ohp_ssh"
echo -e "OHP OpenVPN    : $ovpn_ohp"
echo -e "Port Squid     : $squid_port"
echo -e "Badvpn(UDPGW)  : 7100-7300"
echo -e "=================================="
echo -e "CONFIG SSH WS"
echo -e "--------------"
echo -e "SSH 22      : $domain:22@$Login:$Pass"
echo -e "SSH 80      : $domain:80@$Login:$Pass"
echo -e "SSH 443     : $domain:443@$Login:$Pass"
echo -e "SSH 1-65535 : $domain:1-65535@$Login:$Pass"
echo -e "=================================="
echo -e "CONFIG OPENVPN"
echo -e "--------------"
echo -e "OpenVPN TCP : $ovpn_tcp http://$MYIP:81/client-tcp-$ovpn_tcp.ovpn"
echo -e "OpenVPN UDP : $ovpn_udp http://$MYIP:81/client-udp-$ovpn_udp.ovpn"
echo -e "OpenVPN SSL : $ovpn_ssl http://$MYIP:81/client-tcp-ssl.ovpn"
echo -e "OpenVPN OHP : $ovpn_ohp http://$MYIP:81/client-tcp-ohp1194.ovpn"
echo -e "=================================="
echo -e "PAYLOAD WS       : GET / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf][crlf]"
echo -e "=================================="
echo -e "PAYLOAD WSS      : GET wss://$domain/ HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]"
echo -e "=================================="
echo -e "PAYLOAD WS OVPN  : GET wss://$domain/ HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]"
echo -e "=================================="
echo ""

read -n 1 -s -r -p "Press any key to return to SSH menu"
ssh2
