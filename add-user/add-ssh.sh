#!/bin/bash

GitUser="melody97rain"

# Set PATH for system binaries
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Get public IP
MYIP=$(curl -s ipinfo.io/ip)

echo -e "\e[32mloading...\e[0m"
clear

# PROVIDED and other variables
creditt=$(cat /root/provided 2>/dev/null)
box=$(cat /etc/box 2>/dev/null)
line=$(cat /etc/line 2>/dev/null)
back_text=$(cat /etc/back 2>/dev/null)

clear
echo -e "  \e[$line═══════════════════════════════════════════════════════\e[m"
echo -e "  \e[$back_text           \e[30m[\e[$box CREATE USER SSH & OPENVPN\e[30m ]\e[1m               \e[m"
echo -e "  \e[$line═══════════════════════════════════════════════════════\e[m"

# Loop until valid (non-duplicate) username is input
while true; do
    read -p "   Username : " Login
    if id "$Login" &>/dev/null; then
        echo -e "\e[31mUser '$Login' already exists. Please enter a different username.\e[0m"
    else
        break
    fi
done

read -p "   Password : " Pass
read -p "   Bug SNI/Host (Example : m.facebook.com) : " sni
read -p "   Expired (days): " masaaktif

IP=$(wget -qO- icanhazip.com)
source /var/lib/premium-script/ipvps.conf 2>/dev/null

if [[ -z "$IP" ]]; then
    domain=$(cat /usr/local/etc/xray/domain 2>/dev/null)
else
    domain=$IP
fi

ssl=$(grep -w "Stunnel4" ~/log-install.txt | cut -d: -f2 | xargs)
sqd=$(grep -w "Squid" ~/log-install.txt | cut -d: -f2 | xargs)
ovpn=$(netstat -nlpt 2>/dev/null | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2 | head -1)
ovpn2=$(netstat -nlpu 2>/dev/null | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2 | head -1)
ovpn3=$(grep -w "OHP OpenVPN" ~/log-install.txt | cut -d: -f2 | xargs)
ovpn4=$(grep -w "OpenVPN SSL" ~/log-install.txt | cut -d: -f2 | xargs)
ohpssh=$(grep -w "OHP SSH" ~/log-install.txt | cut -d: -f2 | xargs)
ohpdrop=$(grep -w "OHP Dropbear" ~/log-install.txt | cut -d: -f2 | xargs)
wsdropbear=$(grep -w "Websocket SSH(HTTP)" ~/log-install.txt | cut -d: -f2 | xargs)
wsstunnel=$(grep -w "Websocket SSL(HTTPS)" ~/log-install.txt | cut -d: -f2 | xargs)
wsovpn=$(grep -w "Websocket OpenVPN" ~/log-install.txt | cut -d: -f2 | xargs)

nsdomain1=$(cat /root/nsdomain 2>/dev/null)
pubkey1=$(cat /etc/slowdns/server.pub 2>/dev/null)

echo "Ping Host"
echo "Check Access..."
sleep 1
echo "Permission Accepted"
clear
sleep 1
echo "Create Acc: $Login"
sleep 1
echo "Setting Password: $Pass"
sleep 1
clear

harini=$(date -d "0 days" +"%Y-%m-%d")

# Create user
if /usr/sbin/useradd -e $(date -d "$masaaktif days" +"%Y-%m-%d") -s /bin/false -M "$Login"; then
    echo "User $Login created successfully."
else
    echo -e "\e[31mFailed to create user $Login. Please check your permissions.\e[0m"
    exit 1
fi

exp1=$(date -d "$masaaktif days" +"%Y-%m-%d")
exp=$(/usr/bin/chage -l "$Login" | grep "Account expires" | awk -F": " '{print $2}')

cat > /home/vps/public_html/ssh-$Login.txt << EOF
====================================================================
             P R O J E C T  O F  N I L P H R E A K Z V P N
                       [Freedom Internet]
====================================================================
            https://github.com/‎NiLphreakz/
====================================================================
              Format SSH OVPN Account - SPv2
====================================================================

====================================================================
Premium Account SSH & OpenVPN
====================================================================
Username         : $Login
Password         : $Pass
Created          : $harini
Expired          : $exp1
====================================================================
Domain           : $domain
#Name Server(NS)  : $nsdomain1
#Pubkey           : $pubkey1
IP/Host          : $MYIP
OpenSSH          : 22
Dropbear         : 143, 109
SSL/TLS          : $ssl
#SlowDNS          : 22,80,443,53,5300
SSH-UDP          : 1-65535
WS SSH(HTTP)     : $wsdropbear
WS SSL(HTTPS)    : $wsstunnel
WS OpenVPN(HTTP) : $wsovpn
OHP Dropbear     : $ohpdrop
OHP OpenSSH      : $ohpssh
OHP OpenVPN      : $ovpn3
Port Squid       : $sqd
Badvpn(UDPGW)    : 7100-7300
====================================================================
CONFIG SSH WS
SSH 22      : $(cat /usr/local/etc/xray/domain):22@$Login:$Pass
SSH 80      : $(cat /usr/local/etc/xray/domain):80@$Login:$Pass
SSH 443     : $(cat /usr/local/etc/xray/domain):443@$Login:$Pass
SSH 1-65535 : $(cat /usr/local/etc/xray/domain):1-65535@$Login:$Pass
====================================================================
CONFIG OPENVPN
OpenVPN TCP : $ovpn http://$MYIP:81/client-tcp-$ovpn.ovpn
OpenVPN UDP : $ovpn2 http://$MYIP:81/client-udp-$ovpn2.ovpn
OpenVPN SSL : $ovpn4 http://$MYIP:81/client-tcp-ssl.ovpn
OpenVPN OHP : $ovpn3 http://$MYIP:81/client-tcp-ohp1194.ovpn
====================================================================
PAYLOAD WS       : GET / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf][crlf]
====================================================================
PAYLOAD WSS      : GET wss://$sni/ HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]
====================================================================
PAYLOAD WS OVPN  : GET wss://$sni/ HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]
====================================================================
EOF

echo -e "$Pass\n$Pass\n" | passwd "$Login" &> /dev/null

echo ""
echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"
echo -e "\e[$back_text         \e[30m[\e[$box Premium Account SSH & OpenVPN\e[30m ]\e[1m           \e[m"
echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"

echo -e "Username         : $Login"
echo -e "Password         : $Pass"
echo -e "Created          : $harini"
echo -e "Expired          : $exp1"

echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"

echo -e "Domain           : $domain"
#echo -e "Name Server(NS)  : $nsdomain1"
#echo -e "Pubkey           : $pubkey1"
echo -e "IP/Host          : $MYIP"
echo -e "OpenSSH          : 22"
echo -e "Dropbear         : 143, 109"
echo -e "SSL/TLS          : $ssl"
#echo -e "SlowDNS          : 22,80,443,53,5300"
echo -e "SSH-UDP          : 1-65535"
echo -e "WS SSH(HTTP)     : $wsdropbear"
echo -e "WS SSL(HTTPS)    : $wsstunnel"
echo -e "WS OpenVPN(HTTP) : $wsovpn"
echo -e "OHP Dropbear     : $ohpdrop"
echo -e "OHP OpenSSH      : $ohpssh"
echo -e "OHP OpenVPN      : $ovpn3"
echo -e "Port Squid       : $sqd"
echo -e "Badvpn(UDPGW)    : 7100-7300"

echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"

echo -e "CONFIG SSH WS"
echo -e "SSH Config  : http://${domain}:81/ssh-$Login.txt"
echo -e "SSH 22      : $(cat /usr/local/etc/xray/domain):22@$Login:$Pass"
echo -e "SSH 80      : $(cat /usr/local/etc/xray/domain):80@$Login:$Pass"
echo -e "SSH 443     : $(cat /usr/local/etc/xray/domain):443@$Login:$Pass"
echo -e "SSH 1-65535 : $(cat /usr/local/etc/xray/domain):1-65535@$Login:$Pass"

echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"
echo -e "CONFIG OPENVPN"
echo -e "--------------"
echo -e "OpenVPN TCP : $ovpn http://$MYIP:81/client-tcp-$ovpn.ovpn"
echo -e "OpenVPN UDP : $ovpn2 http://$MYIP:81/client-udp-$ovpn2.ovpn"
echo -e "OpenVPN SSL : $ovpn4 http://$MYIP:81/client-tcp-ssl.ovpn"
echo -e "OpenVPN OHP : $ovpn3 http://$MYIP:81/client-tcp-ohp1194.ovpn"

echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"

echo -e "PAYLOAD WS       : GET / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf][crlf]"
echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"
echo -e "PAYLOAD WSS      : GET wss://$sni/ HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]"
echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"
echo -e "PAYLOAD WS OVPN  : GET wss://$sni/ HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]"
echo ""
read -n 1 -s -r -p "Press any key to back on menu SSH"
ssh2
