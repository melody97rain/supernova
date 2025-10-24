#!/bin/bash
# Pastikan kebergantungan asas
for cmd in curl getent userdel; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo -e "\e[31mError: $cmd tiada. Sila pasang dulu!\e[0m"
        exit 1
    fi
done

GitUser="melody97rain"
# Dapatkan IP pelayan
MYIP=$(curl -s ipv4.icanhazip.com)
[ -z "$MYIP" ] && MYIP=$(curl -s ipinfo.io/ip)
[ -z "$MYIP" ] && MYIP=$(curl -s ifconfig.me)
if [ -z "$MYIP" ]; then
    echo -e "\e[31mGagal dapatkan IP pelayan!\e[0m"
    exit 1
fi

echo -e "\e[32mMemuatkan...\e[0m"
clear

# Padam pengguna SSH
read -rp "Username SSH to Delete: " Pengguna
if getent passwd "$Pengguna" > /dev/null 2>&1; then
    userdel "$Pengguna"
    echo -e "User $Pengguna was removed."
else
    echo -e "Failure: User $Pengguna Not Exist."
fi
