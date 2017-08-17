#!/bin/bash
set -eux
raw_addr=($(awk '$6=="eth0"&&$4==00{print $1,$3}' /proc/net/if_inet6))
pbl=$((${raw_addr[1]}/10))
subnet=$(echo "${raw_addr[0]}" | awk -v FIELDWIDTHS="$(for ((i=1; i<=$pbl; i++)); do echo -n '4 '; done)" \
				     -v OFS=':' '$1=$1')
CEPH_PUBLIC_NETWORK="${subnet}::/$(printf '%d' 0x${raw_addr[1]})"
MON_IP=$(echo "${raw_addr[0]}" | awk -v FIELDWIDTHS='4 4 4 4 4 4 4 4' -v OFS=':' '$1=$1')
export MON_IP CEPH_PUBLIC_NETWORK
exec ${@}
