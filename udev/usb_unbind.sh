#!/bin/bash

if [ -z ${1} ] ; then
	echo "usage : usb_unbind.sh {usb devpath (e.g. /devices/platform/vhci_hcd.0/usb1/1-1, use %p in udev rules)}"
	exit 1
fi
DEVPATH=${1}
BUSNUM=$(echo ${DEVPATH} | rev | cut -d '/' -f 1 | rev)
INTERFACENUM=$(find /sys -regextype posix-basic -regex "/sys${DEVPATH}/${BUSNUM}:[0-9]\+\.[0-9]\+/driver" | rev | cut -d '/' -f 2 | rev)
for IF in ${INTERFACENUM}; do
	echo -n ${IF} > /sys${DEVPATH}/${IF}/driver/unbind
done
