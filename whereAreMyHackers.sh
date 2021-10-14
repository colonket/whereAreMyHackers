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

# Get IP addresses from lastb
ips=$(sudo lastb | awk -F" " '{print $3}' | grep -E '[0-9]' | uniq -c)

# Print something if nothing found
if ((${#ips[@]}))
then
	echo "No failed logins found!"
	exit
fi

# Create new array with IP's frequency before every IP
# Frequency Values appear first (even indexes)
# IP Addresses appear second (odd indexes)
sorted=$(awk '{key=$0; getline; print key "\n" $0;}' <<< $ips)
#sorted="1 a 2 b 3 c 4 d 5 e"

declare -A IPfreq	# Associative Array / Dictionary 
declare -A IPloc	# Associative Array / Dictionary
declare -A countryFreq	# Associative Array / Dictionary

# Mapping IP addresses to countries and frequencies
count=0
for i in $sorted; do
	if (( $count % 2 == 0 ))
	then
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
