#!/bin/bash
log_src='['${0##*/}']'

RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e $log_src[`date +%F.%H:%M:%S`]"$RED Call common startup ... $NC"
startup_common


if [ -f /opt/scripts/init/init ]; then
    echo -e $log_src[`date +%F.%H:%M:%S`]"$RED Call init ... $NC"
    chmod +x /opt/scripts/init/init
    /opt/scripts/init/init
fi
