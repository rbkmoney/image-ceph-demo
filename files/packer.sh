#!/bin/bash

# TODO: use functions from build-utils
function ebegin() {
    local message=$1
    echo -n "-=- ${message} " 1>&2;    
}

function eend() {
    local retcode=$1 fail_message=$2
    if [ $retcode -gt 0 ]; then
	echo "[ !! ]" 1>&2
	eerror "${fail_message}"
	return $retcode
    else
	echo "[ ok ]" 1>&2; return $retcode
    fi
}

function einfo() {
    local message=$1
    echo "-I- ${message}" 1>&2;
}

function ewarn() {
    local message=$1
    echo "-!- ${message}" 1>&2;
}

function eerror() {
    local message=$1
    echo "-!! ${message}" 1>&2;
}
# end

export DEBIAN_FRONTEND=noninteractive

ebegin "Updating repo indices"
apt-get update -q
eend $? "Failed" || exit $?

ebegin "Installing gawk"
apt-get install -qy gawk
eend $? "Failed" || exit $?

ebegin "Installing files"
(
    set -ue
    cp /tmp/data/ceph-set-env.sh /usr/local/bin/ceph-set-env.sh
    chmod +x /bin/ceph-set-env.sh
)
eend $? "Failed" || exit $?

ebegin "Removing temporary directories and logs"
find /var/log -type f ! -name '.keep*' -print -delete
eend $? "Failed" || exit $?
