#!/bin/bash

# Search for InfiniBand devices and wait until at least one is ACTIVE.
# Potential InfiniBand ports will be in /sys/class/infiniband/*/ports/*

maxcount=180
basedir=/sys/class/infiniband
if [ ! -d $basedir ]; then
    logger "$0: No InfiniBand devices found"
    exit 0
fi

# Check if $basedir exists but is empty (meaning no InfiniBand devices).
# This may happen if the ib_core kernel module has been loaded, check with "lsmod | grep ib_core".
device_found=0
for (( count = 0; count < $maxcount; count++ )); do
    if [ -z "$(ls -A $basedir)" ]; then
        sleep 1
    else
        device_found=1
        break
    fi
done
if [[ $device_found -eq 0 ]]; then
    logger "$0: No active InfiniBand devices found"
    exit 1
fi

# Loop over all InfiniBand $basedir/*/ports/ directories until ALL ports have come to exist
for nic in $basedir/*; do
    for (( count = 0; count < $maxcount; count++ )); do
            if [ -d $nic/ports ]; then
                logger "$0: ports directory now exists for NIC $nic"
                break
            else
                sleep 1
            fi
    done
done

# Identify any InfiniBand link_layer ports and add to the ib_ports array.
# The port might be an iRDMA Ethernet port, check it with "rdma link show" or "ibstatus".
# Alternative for explicitly skipping Ethernet iRDMA ports: grep -vqc "Ethernet" ...
for nic in $basedir/*; do
    for port in $nic/ports/*; do
        if grep -qc "InfiniBand" "$port/link_layer"; then
            ib_ports+=( "$port" )
        fi
    done
done

if [ ${#ib_ports[@]} -gt 0 ]; then
    logger "$0: Found ${#ib_ports[@]} InfiniBand link_layer ports: ${ib_ports[*]}"
else
    logger "$0: No InfiniBand link_layer ports found"
    exit 0
fi

# Loop over InfiniBand link_layer ports until one becomes ACTIVE
for (( count = 0; count < $maxcount; count++ )); do
    for port in ${ib_ports[*]}; do
        if grep -qc "ACTIVE" "$port/state"; then
            logger "$0: InfiniBand online at $port"
            exit 0    # Exit when the first InfiniBand becomes active
        else
            sleep 1    # Sleep 1 second
        fi
    done
done

logger "$0: Failed to find an ACTIVE InfiniBand link_layer port in $maxcount seconds"
exit 1
