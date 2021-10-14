#!/usr/bin/env bash

### Title:	whereAreMyHackers.sh
###	Desc:	A script to print how many times IP addresses from
###			various countries fail to login.
###	Author:	Colonket

if ! command -v geoiplookup &> /dev/null
then
	echo "The program 'geoiplookup' could not be found"
	echo "Please install and try again"
	exit
fi

# Get IP addresses from lastb and sort
ips=$(sudo lastb | awk -F" " '{print $3}' | grep -E '[0-9]' | uniq -c)
# Create new array with IP's frequency before every IP
sorted=$(awk '{key=$0; getline; print key "\n" $0;}' <<< $ips)
#sorted="1 a 2 b 3 c 4 d 5 e"

declare -A IPfreq	# Associative Array / Dictionary 
declare -A IPloc	# Associative Array / Dictionary
count=0
declare -A countryFreq	# Associative Array / Dictionary
# Frequency Values appear first (even indexes)
# IP Addresses appear second (odd indexes)

for i in $sorted; do
	if (( $count % 2 == 0 ))
	then
		IPfreqVal=$i
	else
		country=$(geoiplookup $i | awk -F": " '{print $NF}')
		if [[ -z ${countryFreq[$country]} ]]; then
			# If the country hasn't been encountered before
			countryFreq[$country]=1	# Start counting how many times it appears
		else
			# Increment the country's frequency value for each new occurance
			((countryFreq[$country]+=1))
		fi
		# Record the Location and Frequency of each IP address
		IPloc[$i]=$country
		IPfreq[$i]=$IPfreqVal
		#echo "$i ${IPloc[$i]} ${IPfreq[$i]}"	# IP, Location, Frequency
	fi
	count=$((count+1))
done

for key in "${!countryFreq[@]}"
do
	echo "$key:${countryFreq[$key]}"
done |
sort -t':' -k2n
