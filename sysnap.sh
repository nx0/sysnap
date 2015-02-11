#!/bin/bash

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

function get_distro {
	header "distro"
	for d in SuSE centos debian redhat; do
		stat /etc/$d-release 1>&2>/dev/null
		if [ $? -eq 0 ]; then
			case $d in
				SuSE)
					p_version=`zypper -V 2>&1>/dev/null`
					function check_rep {
						echo `zypper sl | grep -v devices | grep -Ei '(yes|no)' | awk -F '|' '{ print $2 }' | sort | uniq -c`
					}
				;;
				centos)

				;;
				debian)

				;;
				redhat)

				;;
				*)
					echo "Desconocida"
			esac
			
			echo `lsb_release -a | tail -n 3 | cut -d ":" -f 2`
			return 0
			#cat /etc/$d-release
		fi
	done
}

function get_kernel {
	header "kernel"
	uname -r
}

function tmp {
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
	cat /proc/cpuinfo | grep "model name"| cut -d ":" -f 2 | sed 's/^ *//g'
}

function get_mhz {
	header "mhz"
	echo `cat /proc/cpuinfo | grep -i mhz | awk -F ":" '{ print $2 }'`
}

function get_cpusize {
	echo `cat /proc/cpuinfo | grep "clflush size"| awk -F ":" '{ print $2 }'`
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

function get_user {
	header "usuarios"
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

function get_dmesg {
	header "dmesg error/problem/crash"
	echo `dmesg | tail | grep -Ei "error|problem|crash"`
	if [ !$? ]; then
		echo ""
	fi
}

function get_cluster {
	header "cluster"
	cluster=`ls /etc/init.d/ | grep -Ei "corosync|heartbeat|openais" | head -n 1`
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
	header "model"
	echo `dmidecode | grep -Ei "manufacturer" | head -n 1|awk -F ":" '{ print $2 }'`
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
	header "$1 running"
	run=`ps ax| grep $1 | grep -v grep | wc -l`
	if (( $run >= 1 )); then
		echo "ok $2"
	else
		echo "no"
	fi
}

function get_xinet_serv {
	header "xinet serv:"
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
	header "free space (mapper/sda)"
	echo `df -Ph | column -t | grep -Ei "mapper|sda"| awk '{ print $1 " (" $4 ")" }'`
}

echo "	
               _        __       
 ___ _   _ ___(_)_ __  / _| ___  
/ __| | | / __| | '_ \| |_ / _ \ 
\__ \ |_| \__ \ | | | |  _| (_) |
|___/\__, |___/_|_| |_|_|  \___/ 
     |___/ by: FJ Valero - e: hackgo@gmail.com                      
____________________________________________________
"

get_hostname
get_distro
get_kernel
get_uptime
tmp
get_model
get_pmanager
get_repos

header_top "resources"
get_mem
get_cpu
get_mhz
get_cpumodel


header_top "processes"
get_proc ntp
get_proc http
get_proc xinet
get_proc ftpd
get_proc vnetd "netbackup"


header_top "packages"
get_whereis locate
get_whereis htop
get_whereis rug "(zenworks package)"
get_whereis rmt "(cintas)"


header_top "storage"
get_mount
#echo "LVM: "
get_lvm
get_storage


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


header_top "cluster"
get_cluster


header_top "networking"
get_dns
get_search
get_hosts
get_bridge
get_netw
get_iface


header_top "system activity"
get_last
get_lastlog
get_dmesg
get_messages
user_logged
