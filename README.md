<h2 align="center">

♦️Autoscript SSH XRAYS Websocket Multiport By ‎NiLphreakz♦️



 <h2 align="center">AutoScriptVPN <img src="https://img.shields.io/badge/Version-Stable_3.0-purple.svg"></h2>


<h2 align="center"> Supported Linux Distribution</h2>
<p align="center"><img src="https://d33wubrfki0l68.cloudfront.net/5911c43be3b1da526ed609e9c55783d9d0f6b066/9858b/assets/img/debian-ubuntu-hover.png"width="400"></p>
<p align="center"><img src="https://img.shields.io/static/v1?style=for-the-badge&logo=debian&label=Debian%2012&message=Bookworm&color=purple"> <img src="https://img.shields.io/static/v1?style=for-the-badge&logo=debian&label=Debian%2013&message=Trixie&color=purple">  <img src="https://img.shields.io/static/v1?style=for-the-badge&logo=ubuntu&label=Ubuntu%2024&message=Focal&color=red"> <img src="https://img.shields.io/static/v1?style=for-the-badge&logo=ubuntu&label=Ubuntu%2025&message=Beta&color=red">
</p>

<p align="center">

## Register IP ( PM username & IP-VPS ) : <a href="https://t.me/NiLphreakz" target=”_blank”><img src="https://img.shields.io/static/v1?style=for-the-badge&logo=Telegram&label=Telegram&message=Click%20Here&color=blue"></a><br>


## ⚠️ PLEASE README ⚠️


 PLEASE MAKE SURE YOUR DOMAIN SETTINGS IN YOUR CLOUDFLARE AS BELOW (SSL/TLS SETTINGS) <br>
  1. Your SSL/TLS encryption mode is Full
  2. Enable SSL/TLS Recommender ✅
  3. Edge Certificates > Disable Always Use HTTPS : OFF
  4. UNDER ATTACK MODE : OFF
  5. WEBSOCKET : ON
  
## ⚠️ System Requirements ⚠️
1. Minimum 1GB RAM
2. Support Debian/Ubuntu Old & Latest OS
3. Xray-Core v1.7.5 or lower requirements for this script. Latest Xray-Core will not support XTLS.
4. This is latest script remodded by NiLphreakz

## ♦️Update & Upgrade First Your VPS for Debian♦️

  ```html
  apt-get update && apt-get upgrade -y && update-grub && sleep 2 && reboot
  
  ```
 or
 
 
   ```html
  apt update -y && apt upgrade -y && apt dist-upgrade -y && reboot

  ```

## ♦️Update & Upgrade First Your VPS for Ubuntu♦️

  ```html
  apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && sleep 2 && reboot

  ```
  
 or
   ```html
  apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && reboot

  ```
 
 
## ♦️INSTALLATION SCRIPT♦️
ipv4 only
  ```html
sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 && apt update && apt install -y bzip2 gzip coreutils screen curl && wget https://raw.githubusercontent.com/melody97rain/multiport/main/setup.sh && chmod +x setup.sh && sed -i -e 's/\r$//' setup.sh && screen -S setup ./setup.sh

  ```
or 
 ```html
sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 && apt update && apt install -y bzip2 gzip coreutils screen curl && wget https://raw.githubusercontent.com/‎melody97rain/supernova/main/setup2.sh && chmod +x setup2.sh && sed -i -e 's/\r$//' setup2.sh && screen -S setup ./setup2.sh

  ```
ipv4 + ipv6
 ```html
apt update && apt install -y bzip2 gzip coreutils screen curl && wget https://raw.githubusercontent.com/‎melody97rain/supernova/main/setup3.sh && chmod +x setup3.sh && sed -i -e 's/\r$//' setup3.sh && screen -S setup ./setup3.sh
  ```
  

## Description :

  Service & Port:-

  - OpenSSH                 : 22
  - OpenVPN                 : TCP 1194, UDP 2200, SSL 110
  - Stunnel4                : 222, 777
  - Dropbear                : 442, 109
  - SSH-UDP                 : 1-65535
  - OHP Dropbear            : 8585
  - OHP SSH                 : 8686
  - OHP OpenVPN             : 8787
  - Websocket SSH(HTTP)     : 80
  - Websocket SSL(HTTPS)    : 443, 222
  - Websocket OpenVPN       : 2084
  - NoobzVpn(HTTP)          : 8080
  - NoobzVpn(HTTPS)         : 8443 
  - Squid Proxy             : 3128, 8000
  - Badvpn                  : 7100, 7200, 7300
  - Nginx                   : 81
  - XRAY Vmess Ws Tls       : 443
  - XRAY Vless Ws Tls       : 443
  - XRAY Trojan Ws Tls      : 443
  - XRAY Vless Tcp Xtls     : 443
  - XRAY Trojan Tcp Tls     : 443
  - XRAY Vmess Ws None Tls  : 80
  - XRAY Vless Ws None Tls  : 80
  - XRAY Trojan Ws None Tls : 80

 Server Information & Other Features:-
 
   - Timezone                 : Asia/Kuala_Lumpur (GMT +8)
   - Fail2Ban                 : [ON]
   - DDOS Dflate              : [ON]
   - IPtables                 : [ON]
   - Auto-Reboot              : [ON] - 5.00 AM
   - IPv6                     : [OFF]
   - Auto-Remove-Expired      : [ON]
   - Auto-Backup-Account      : [ON]
   - Fully automatic script
   - VPS settings
   - Admin Control
   - Change port
   - Change Dropbear Version

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


<p align="center">
  <a><img src="https://img.shields.io/badge/Copyright%20©-Onyx%20AutoScriptVPN%202023.%20All%20rights%20reserved...-blueviolet.svg" style="max-width:200%;">
    </p>
   </p>
