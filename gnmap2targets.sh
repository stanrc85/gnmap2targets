#!/bin/bash
#Gnmap files are parsed for common ports to generate individual IP lists for further testing or scanning.

#Usage: ./gnmap2targets.sh GNMAP_FILE
#Output: All associated NMAP results and multiple txt files with IPs

#Colors
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'


#Parse live host list. Exit if no live hosts found.
scan=$(echo $1 | cut -d'.' -f1)
cat $1 | grep "Status: Up" | cut -d" " -f2 > $scan-live-hosts.txt 
count=$(cat $scan-live-hosts.txt | wc -l)
if [[ "$count" == 0 ]]; then
	echo -e "${RED}[+] No live hosts found.  Exiting.${NOCOLOR}"
	exit
fi
echo -e "${GREEN}[+] $count live hosts found.${NOCOLOR}"

#Parse results for common ports
servicelist=(ssh telnet smtp sql smb dns snmp)
for service in ${servicelist[@]}
do
	cat $1 | grep "$service" | cut -d' ' -f2 > $scan-$service-hosts.txt
	echo -e "${GREEN}[+] $(cat $scan-$service-hosts.txt | wc -l) $service hosts found.${NOCOLOR}"
	if [ ! -s $scan-$service-hosts.txt ] ; then
		rm $scan-$service-hosts.txt
	fi
done

#Parse GNMAP to generate txt file with IP:PORT list for all web services
input="$1"
echo -e "${GREEN}[+] Reading file to parse HTTP/S services.${NOCOLOR}"
filename=$( echo $1 | cut -d'.' -f1)
webcount=0
while IFS= read -r line
do
	if [[ $line == *"Ports: "* ]]; then
		ip=$(echo $line | cut -d' ' -f2)
		ports=$(echo $line | cut -d' ' -f4-)
		portlist=$(echo $ports | cut -d' ' -f2- | tr ',' '\n')
		for port in $portlist
		do
			if [[ "$port" == *"open"* ]]; then
				if [[ "$port" == *"http"* && "$port" != *"https"* && "$port" != *"ssl"* ]]; then
					portopen=$(echo $port | cut -d'/' -f1)
					echo "http://$ip:$portopen" >> $filename-web-hosts.txt
					http_ports="$http_ports, $portopen"
					((webcount++))
				elif [[ "$port" == *"ssl"* || "$port" == *"https"* ]]; then
					portopen=$(echo $port | cut -d'/' -f1)
					echo "https://$ip:$portopen" >> $filename-web-hosts.txt
					http_ports="$http_ports, $portopen"
					((webcount++))
				fi
			fi
		done	
	fi
done<"$input"
cat $filename-web-hosts.txt | sort | uniq > sorted
mv -f sorted $filename-web-hosts.txt 
echo -e "${GREEN}[+] $webcount web services identified.\n[+] Saved to $filename-web-hosts.txt.${NOCOLOR}"

echo -e "${GREEN}[+] Target lists complete.${NOCOLOR}"
