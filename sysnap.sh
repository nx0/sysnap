#!/bin/bash
# TODO: Ubuntu /var/log/messages logfile
# TODO: check if I'm root to perform the checks


function header_top {
	#echo "<======| | $1 | |======>"
	echo "------------------| $1 |------------------"
}

function header {
	echo -n "* $1: "
}

function get_hostname {
	#header "hostname"
	echo "[ `hostname --fqdn | head -n 1` ]"
}

function l_release {
	dist=`lsb_release -a 2>/dev/null| tail -n 3 | cut -d ":" -f 2`
	if [ $? -eq 0 ]; then
		echo `echo $dist`
	else
		echo "--- unknown ---"
	fi
}

function get_distro {
	header "distro"
	d=`lsb_release -i -s`
		case $d in
			"SUSE LINUX")
				p_version=`zypper -V 2>&1>/dev/null`
				function check_rep {
					echo `zypper sl | grep -v devices | grep -Ei '(yes|no)' | awk -F '|' '{ print $2 }' | sort | uniq -c`
				}

				function check_r_h {
					echo n |zypper if nmap 2>&1>/dev/null 2>/dev/null
					if [ $? -eq 255 ]; then
						echo "no"
					else
						echo "YES"
					fi
				}
					
				# officially repos (smt)
				function of_repos {
					zypper sl | grep -iE "novel|SLES" | grep -v iso >/dev/null
					if [ $? -eq 0 ]; then
						echo "YES"
					else
						echo "no"
					fi
				}

				function check_sec_updates {
					header "sec updates"
					zypper pch 2>/dev/null| grep security| grep -i needed| wc -l
				}
			;;
			centos)
				function of_repos {
					echo "YES"
				}

				function check_sec_updates {
					header "sec updates"
					echo "no"
				}
			;;
			debian|Ubuntu)
				p_version=`apt-get -v | head -n 1`
					
				function check_rep {
					echo "YES"
				}

				function check_r_h {
					echo "YES"
				}

				function of_repos {
					echo "YES"
				}

				function check_sec_updates {
					header "sec updates"
					echo "no"
				}
			;;
			RedHatEnterpriseES|RedHatEnterpriseServer)
				function check_rep {
					echo "YES"
				}

				function check_r_h {
					echo "YES"
				}

				function of_repos {
					echo "YES"
				}

				function check_sec_updates {
					header "sec updates"
					echo "no"
				}
			;;
			*)
				function check_r_h {
					echo "YES"
				}

				function of_repos {
					echo "YES"
				}

				function check_sec_updates {
					header "sec updates"
					echo "no"
				}
	esac
			
	#echo `lsb_release -a 2>/dev/null| tail -n 3 | cut -d ":" -f 2`
	l_release
	return 0
}

function get_ofrepos {
	header "of. repos"
	of_repos	
}

function get_kernel {
	header "kernel"
	uname -r
}

function get_tmp {
	header "strange files in /tmp (sh, exe)"
	find /tmp/ -regextype posix-egrep -regex ".*\.(sh|exe)$" | wc -l
}

function get_mount {
	header "mounts"
	mount | wc -l
}

function get_lvm {
	header "log. vol"
	echo `lvs | grep -v "%" | awk '{ print $1 " VG: (" $2  ")" }'`
}

function get_cpumodel {
	header "model"
	cat /proc/cpuinfo | grep "model name"| cut -d ":" -f 2 | sed 's/^ *//g' | head -n 1
}

function get_mhz {
	header "mhz"
	echo `cat /proc/cpuinfo | grep -i mhz | awk -F ":" '{ print $2 }' | head -n 1`
}

function get_cpusize {
	echo `cat /proc/cpuinfo | grep "clflush size"| awk -F ":" '{ print $2 }' | head -n 1`
}

function get_cpu {
	header "cpu"
	echo -n "x`cat /proc/cpuinfo | grep processor| wc -l`"; echo " (`get_cpusize` bits)"
}

function get_part {
	fdisk -l | grep Disk | wc -l
}

function get_mem {
	# base 1000
	header "memory"
	memtotal=`cat /proc/meminfo | head -n 1 | awk '{ print $2 }'`; let t=$memtotal/1000/1000
	echo "$t GB"
}

function get_memperc {
	header "free memory (%)"
	echo `grep -E "MemTotal|MemFree|^Cached:" /proc/meminfo | awk -F ":" '{ print $2 }' | tr -d "kB" | tr -d " "` | awk '{ FREE=$2+$3; print FREE/$1*100 }'	| cut -d "." -f 1|tr "," "."
}

function get_user {
	header "users"
	cat /etc/passwd | awk -F ":" '$4 > 1000' | wc -l
}

function get_sudo {
	header "sudo"
	cat /etc/sudoers | grep -v "#" | sed '/^\s*$/d' | wc -l
}

function get_access {
	header "access"
	cat /etc/security/access.conf | grep -v "#" | sed '/^\s*$/d' | wc -l
}

function get_space {
	df -P
}

function get_netw {
	header "stats"
	echo `netstat -putelna| grep -E "ESTABLISHED|SYN" | awk '{ print $6 }'| sort | uniq -c`
}

function get_iface {
	header "iface"
	echo `ip -o addr| grep inet | awk '{ print $2 " (" $4 ")" }' | column -t`
}

function get_uptime {
	header "uptime"
	uptime | grep -v "#" | sed '/^\s*$/d' | awk '{ print $3 }'
}

function get_last {
	header "last login"
	echo `last | awk '{ print $1 }' | sort |sed '/^\s*$/d'| uniq -c | grep -v wtmp`
}

function get_lastlog {
	header "last login"
	echo `lastlog | grep -vE 'Never|Username' | awk '{ print $1 }'`
}

function get_limits {
	header "system limits"
	cat /etc/security/limits.conf| grep -Ev "#" | sed '/^\s*$/d' | wc -l
}

function get_printcap {
	header "impresion"
	cat /etc/printcap | wc -l 
}

function get_dmesg {
	header "dmesg error/problem/crash"
	echo `dmesg | tail | grep -Ei "error|problem|crash"`
	if [ !$? ]; then
		echo "-"
	fi
}

function get_cluster {
	header "cluster"
	cluster=`ls /etc/init.d/ | grep -Ei "cman|corosync|heartbeat|openais" | head -n 1`
	case $cluster in
		corosync)
			echo $cluster
		;;
		heartbeat)
			echo $cluster	
		;;
		
		openais)
			echo $cluster
		;;

		*)
			echo "no"
		esac
}

function get_messages {
	tail /var/log/messages | grep -E "error|problem|crash"
}

function get_model {
	header "vendor"
	#echo `dmidecode | grep -Ei "manufacturer" | head -n 1|awk -F ":" '{ print $2 }'`
	get_whereis dmidecode > /dev/null
	if [ $? -eq 0 ]; then 
		dmdeco=`dmidecode 2>/dev/null| grep -i vendor | head -n 1| awk -F ":" '{ print $2 }'`
		if [ "$dmdeco" == "" ]; then
			echo "--unknown--"
		else
			echo $dmdeco
		fi
	else
		echo "--unknown--"
	fi
}

function user_logged {
	header "logged user"
	echo `w -h | awk '{ print $1 }' | sort | uniq -c`
}

function get_dns {
	header "dns"
	echo `cat /etc/resolv.conf | awk '/nameserver/{ print $2 }'` | tr " " "/"	
}

function get_search {
	header "search"
	echo `cat /etc/resolv.conf | awk '/search/{ print $2 }'` | tr " " "/"	
}

function get_hosts {
	header "hosts"
	cat /etc/hosts| grep -v "#" | wc -l
}

function get_proc {
	header "$1"
	run=`ps ax| grep $1 | grep -v grep | wc -l`
	if (( $run >= 1 )); then
		echo "YES $2"
	else
		echo "no"
	fi
}

function get_xinetserv {
	header "xinet srv (active)"
	echo `grep -E "disable.*?=*.?no" /etc/xinetd.d/*| awk -F ":" '{ print $1 }' | awk -F "/" '{ print $NF }'`| tr " " "|"
}

function get_whereis {
	header "$1 present"
	where=`whereis $1 | awk -F ":" '{ print $2 }'`
	if [ "$where" != "" ]; then
		echo "$2 ok"
		return 0
	else
		echo "$2 not installed"
		return 1
	fi
}

function get_bridge {
	header "bridges"
	get_whereis brctl > /dev/null
	if [ $? -eq 0 ]; then
		echo "with bridges"
		# TODO
	else
		echo "no bridges"
	fi
}

function get_pmanager {
	header "package manager"
	echo $p_version
}

function get_repos {
	header "repos"
	check_rep
}

function get_storage {
	header "free space (mapper/sda/cciss)"
	echo `df -Ph | column -t | grep -Ei "mapper|sda|cciss"| awk '{ print $1 " (" $4 ")" }'`
}

function get_storagefree {
	header "disk free"
	DF=`df -Pk | column -t | grep -Ei "mapper|sda|cciss"| awk '{ SUM += $4; print SUM/1024/1024 "G" }'| tail -n 1`
	echo $DF
}

function get_storagetotal {
	header "disk total"
	DT=`df -Pk | column -t | grep -Ei "mapper|sda|cciss"| awk '{ SUM += $2; print SUM/1024/1024 "G" }'| tail -n 1`
	echo $DT
}

function get_storagepercent {
	header "disk free (%)"

	get_storagetotal 2>&1>/dev/null
	get_storagefree 2>&1>/dev/null

	TD=`df -Pk | column -t | grep -Ei "mapper|sda|cciss"|wc -l|tr -d " "`
        TT=`df -hP | awk '{ print $5 }' | grep -E "^[1-9]" | tr -d "%"`

        let df=$TT/$TD
        let df=100-$df

        echo $df
}

function get_cpucores {
	header "cpucores"
	ncore=$(cat /proc/cpuinfo | grep "cores"| wc -l) ; core=$(grep cores /proc/cpuinfo | awk -F ":" '{ print $2 }' | head -n 1); 
	if [ "$ncore" == "" ] ; then
		ncore=0
	elif [ "$core" == "" ]; then
		core=0
	fi
	let c="$ncore*$core"
	echo $c
}

function get_cpufree {
	header "cpu free (%)"
	us=`grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage }'`
	usg=`echo $us|tr "," "." | cut -d "." -f1`
	let xxx=100-$usg
	echo "$xxx"
}

function get_bonding {
	header "network redundancy"
	active=`ls /proc/net/bonding/ 2>&1> /dev/null 2>/dev/null`
	if [ "$active" == "0" ]; then
		echo "YES"
	else
		echo "no"
	fi
}

function get_repohealth {
		header "repo updateable"
		check_r_h
	}

function get_virt {
	# vmare
	header "VMWare virt"
	vm=`lspci | grep -i vmware | wc -l`
	if [ "$vm" -gt 0 ]; then
		echo "YES"
	else
		echo "no"
	fi
}

########### compat test ##############

case `uname -s` in
	Linux)
		true
	;;
	VMkernel)
		exit 1
	;;
	*)
		exit 1
esac

######################################
if [ "$2" != "--nobanner" ]; then
echo "	
               _        __       
 ___ _   _ ___(_)_ __  / _| ___  
/ __| | | / __| | '_ \| |_ / _ \ 
\__ \ |_| \__ \ | | | |  _| (_) |
|___/\__, |___/_|_| |_|_|  \___/ 
     |___/ by: FJ Valero - e: hackgo@gmail.com                      
____________________________________________________
"
fi


case $1 in 
	--all|-a)
get_hostname
get_distro
get_kernel
get_uptime
get_tmp
get_model
get_pmanager
get_repos
get_repohealth

header_top "resources"
get_mem
get_cpu
get_cpucores
get_mhz
get_cpumodel
get_cpufree


header_top "processes running"
get_proc ntp
get_proc http
get_proc xinet
get_proc ftpd
get_proc nagios # monitor
get_proc netdisco # monitor.
get_proc vnetd "netbackup"
get_proc saposcol "sap"
get_proc nscd "name cache daemon"
get_proc lpd "printer daemon"
get_proc irqbalance
get_proc vnetd "netbackup"
get_proc nxserver "remote access"
get_proc mysqld
get_proc atop
get_proc smbd
get_proc cups
get_proc named "dns server"
get_proc dnsmasq "dns server"
get_proc lighttpd "web server"
get_proc vcloud-director "vmware vcloud director"
get_proc amavisd "antivir correo"
get_proc smtpd
get_proc postfix "servidor de correo"
get_proc tftp
get_proc slapd "ldap server"
get_proc epmd "erlang computation DNS"
get_proc vmtoolsd "VMWare Tools"
get_proc rhnsd "RedHat network updates"
get_proc miniserv.pl "webmin"
get_proc resmgrd "resource manager"
get_proc pav_control_po "panda software"
get_proc postgres

header_top "packages"
get_whereis locate
get_whereis htop
get_whereis rug "(zenworks package)"
get_whereis rmt "(tape server)"


header_top "storage"
get_mount
get_lvm
get_storage
get_storagetotal
get_storagefree


header_top "users"
#echo "===== partitions ====="
#get_part
#echo "===== space ====="
#get_space
#echo "===== users ====="
get_user
#echo "===== sudoers ====="
get_sudo
#echo "===== access ====="
get_access


header_top "system config"
get_limits
get_printcap
get_xinetserv


header_top "cluster"
get_cluster


header_top "networking"
get_dns
get_search
get_hosts
get_bridge
get_netw
get_iface
get_bonding

header_top "system activity"
get_last
get_lastlog
get_dmesg
get_messages
user_logged

;;
	--executive|-e)
		get_hostname
		get_distro
		get_kernel
		get_cpumodel
		get_model
		get_cpu
		get_cpucores
		get_storagepercent
		get_cpufree 
		get_memperc
		#get_repohealth
		get_proc tnslsnr "oracle"
		get_ofrepos
		get_bonding
		get_cluster
		check_sec_updates
;;
	-s)
		get_distro
		get_kernel
		get_virt
	;;
	*)
		echo "options: <[--all|-a], [--executive|-e]>"
esac
