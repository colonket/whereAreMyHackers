#!/usr/bin/env bash

### Title:	whereAreMyHackers.sh
###	Desc:	A script to print how many times IP addresses from
###			various countries fail to login.
###	Author:	Colonket

# Check if geoiplookup is installed
if ! command -v geoiplookup &> /dev/null
then
	echo "The binary 'geoiplookup' could not be found"
	echo "You may be able to install the binary through the geoip-bin package"
	exit
fi

# Script needs to be run as root to use lastb
if [ "$EUID" -ne 0 ]
then
	echo "Please run as root 'sudo ./whereAreMyHackers.sh'"
	exit
fi

# Store IP addresses from lastb into array 'ips'
ips=$(sudo lastb | awk -F" " '{print $3}' | grep -E '[0-9]' | uniq -c)

# Print something if nothing found
if ((${#ips[@]}))
then
	echo "No failed logins found!"
	exit
fi

# Frequency Values appear first (even indexes, starting at 0)
# IP Addresses appear second (odd indexes, starting at 1)
sorted=$(awk '{key=$0; getline; print key "\n" $0;}' <<< $ips)
#sorted="1 IPA 2 IPB 3 IPC 4 IPD 5 IPE"

# Initiate Dictionaries / Associative Arrays
declare -A IPfreq		# IP:Frequency
declare -A IPloc		# IP:Location
declare -A countryFreq	# Country:Frequency

# Mapping IP addresses to countries and frequencies
count=0
for i in $sorted; do
	if (( $count % 2 == 0 ))
	then
		# How many times an IP address appeared
		IPfreqVal=$i
	else
		country=$(geoiplookup $i | awk -F": " '{print $NF}')
		if [[ -z ${countryFreq[$country]} ]]; then
			# The country has not been counted yet
			countryFreq[$country]=1	
		else
			# The country has been counted already
			((countryFreq[$country]+=1))
		fi
		IPloc[$i]=$country
		IPfreq[$i]=$IPfreqVal
		#echo "$i ${IPloc[$i]} ${IPfreq[$i]}"	# IP, Location, Frequency
	fi
	count=$((count+1))
done

# Print Countries by IP address count
for key in "${!countryFreq[@]}"
do
	echo "$key:${countryFreq[$key]}"
done |
sort -t':' -k2n
