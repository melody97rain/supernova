clear
echo Installing Websocket-SSH Python
sleep 1
echo Sila Tunggu Sebentar...
sleep 0.5
cd

# // GIT USER
GitUser="melody97rain"
namafolder="websocket-python"

# // SYSTEM WEBSOCKET HTTPS 443
cat <<EOF> /etc/systemd/system/ws-https.service
[Unit]
Description=Python Proxy
Documentation=https://nilphreakz.xyz
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
User=root

# Pastikan WorkingDirectory wujud (berguna untuk relative paths)
WorkingDirectory=/usr/local/bin

# Optional file untuk argumen (elak amaran "Referenced but unset environment variable")
EnvironmentFile=-/etc/default/python-proxy

# Gunakan python3 unbuffered (-u) supaya logs keluar segera
ExecStart=/usr/bin/python3 -u /usr/local/bin/ws-https $PY_PROXY_OPTS

Restart=on-failure
RestartSec=5

# Send stdout/stderr to journal
StandardOutput=journal
StandardError=journal

# Lightweight hardening
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
NoNewPrivileges=true
PrivateDevices=true
KillMode=control-group
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
EOF

# // SYSTEM WEBSOCKET HTTP 80
cat <<EOF> /etc/systemd/system/ws-http.service
[Unit]
Description=Python Proxy
Documentation=https://virtual.xyz
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=proxy
WorkingDirectory=/usr/local/bin
ExecStart=/usr/bin/python3 -u /usr/local/bin/ws-http
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

# Hardening
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
NoNewPrivileges=true
PrivateDevices=true
KillMode=control-group
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
EOF

# // SYSTEM WEBSOCKET OVPN
cat <<EOF> /etc/systemd/system/ws-ovpn.service
[Unit]
Description=Python Proxy
Documentation=https://github.com/NiLphreakz/
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/python3 -O /usr/local/bin/ws-ovpn 2097
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# // PYTHON WEBSOCKET TLS && NONE
wget -q -O /usr/local/bin/ws-https https://raw.githubusercontent.com/${GitUser}/supernova/main/${namafolder}/ws-https; chmod +x /usr/local/bin/ws-https

# // PYTHON WEBSOCKET DROPBEAR
wget -q -O /usr/local/bin/ws-http https://raw.githubusercontent.com/${GitUser}/supernova/main/${namafolder}/ws-http; chmod +x /usr/local/bin/ws-http

# // PYTHON WEBSOCKET OVPN
wget -q -O /usr/local/bin/ws-ovpn https://raw.githubusercontent.com/${GitUser}/supernova/main/${namafolder}/ws-ovpn; chmod +x /usr/local/bin/ws-ovpn

# // RESTART && ENABLE SSHVPN WEBSOCKET TLS 
systemctl daemon-reload
systemctl enable ws-https
systemctl restart ws-https
systemctl enable ws-http
systemctl restart ws-http
systemctl enable ws-ovpn
systemctl restart ws-ovpn
