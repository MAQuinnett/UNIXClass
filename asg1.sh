#!/bin/bash
set -e

function IPtoBIN(){

	CONV=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})

	ip=""
	for byte in `echo ${1} | tr "." " "`; do
		ip="${ip}.${CONV[${byte}]}"
	done
	echo ${ip:1}

}

function BINtoIP(){

	echo "$((2#${1:0:8})).$((2#${1:9:8})).$((2#${1:18:8})).$((2#${1:27:8}))"

}

function Compare(){

	if [ $1 != 1 ] || [ $2 != 1 ]; then
		echo "0"
	else
		echo "1"
	fi

}

while getopts ":o:i:m:n:s:h:" options; do
	case $options in
		o) choice="$OPTARG";;
		i) ip1="$(cut -d',' -f1	<<<"$OPTARG")"
		   ip2="$(cut -d',' -f2 <<<"$OPTARG")";;
		m) netMask="$OPTARG";;
		n) netAddr="$OPTARG";;
		s) numSubs="$OPTARG";;
		h) numHosts="$OPTARG";;
	esac
done

if [[ $choice -eq 1 ]]; then
	
	ip1BIN=`IPtoBIN "${ip1}"`
	ip2BIN=`IPtoBIN "${ip2}"`
	maskBIN=`IPtoBIN "${netMask}"`
	bits=34 #-1 with decimals
	for ((i=0;i<=bits;i++)) do
		if [ $i != 8 ] && [ $i != 17 ] && [ $i != 26 ]; then 
			ip1Compare="${ip1Compare}`Compare ${ip1BIN:i:1} ${maskBIN:i:1}`"
			ip2Compare="${ip2Compare}`Compare ${ip2BIN:i:1} ${maskBIN:i:1}`"
			ip1CompareNoDec="${ip1CompareNoDec}`Compare ${ip1BIN:i:1} ${maskBIN:i:1}`"
		else
			ip1Compare="${ip1Compare}."
			ip2Compare="${ip2Compare}."
		fi
	done
	
	if [ $ip1Compare == $ip2Compare ]; then
		echo "IP Addresses $ip1 and $ip2 are on the same network `BINtoIP $ip1Compare`"
	elif [ $ip1Compare != $ip2Compare ]; then #Don't know why else won't work here???
		echo "IP Addresses $ip1 and $ip2 are on different networks (`BINtoIP $ip1Compare`, `BINtoIP $ip2Compare` respectively)"
	fi

elif [[ $choice -eq 2 ]]; then

	ipStart="$(cut -d'.' -f1 <<< $netAddr)";
	if [ $ipStart -gt 191 ]; then
		maskBits=24
	elif [ $ipStart -lt  127 ]; then
		maskBits=8
	else
		maskBits=16
	fi
	if [ $numSubs -lt 128 ]; then
		smallPow=7 #Smallest Power numSubs fits into
		if [ $numSubs -lt 64 ]; then
			smallPow=6
			if [ $numSubs -lt 32 ]; then
				smallPow=5
				if [ $numSubs -lt 16 ]; then
					smallPow=4
					if [ $numSubs -lt 8 ]; then
						smallPow=3
						if [ $numSubs -lt 4 ]; then
							smallPow=2
							if [ $numSubs -lt 2 ]; then
								smallPow=1
								if [ $numSubs -lt 1 ]; then
									smallPow=0
								fi
							fi
						fi
					fi
				fi
			fi	
		fi
	fi
	maskBits=$((maskBits + smallPow))	
	subnets=$((2**$smallPow))
	remainderBits=$(($subnets - $maskBits))
	hosts=$((2**$remainderBits))
	hosts=$(($hosts - 2))
	echo "Subnet mask () will provide $subnets subnets with up to $hosts hosts per subnet."
fi
