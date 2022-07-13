#!/bin/bash
#
# This script is called indirectly from a udev rule, in response to a USB
# serial port device being installed. Start a socket server to tunnel all
# serial traffic over TCP/IP. A remote VISA client can then connect to this
# socket to control the instrument.
#
# See the associate udev.rules file for reference.
#
# This script takes 2 arguments:
#
SERIAL_PORT=$1
TCP_PORT=$2

PATH=/usr/bin/:$PATH

if [ "$SERIAL_PORT" == "" -o "$TCP_PORT" == "" ]; then
    echo "Must provide SERIAL_PORT and TCP_PORT arguments to this script!"
    logger "Must provide SERIAL_PORT and TCP_PORT arguments to this script!"
    exit 1
fi

logger "Starting TCP/IP socket on port $TCP_PORT for serial port $SERIAL_PORT"

# Configure the serial port. Only power supplies max out at 9600 bps.
# Power supply uses DTR/DTS handshake, which is unfortunately not supported.
stty -F $SERIAL_PORT 9600 cs8 -parenb -cstopb raw -echo -echoe -echok -crtscts

# Spawn this in the background so it detaches from the parent process.
# Wait for serial port node to exist, then spawn ncat.
# Use ncat -k so it stays around even after a socket closes.
(until [ -e $SERIAL_PORT ]; do 
     sleep 1	# Wait for symlink creation by udev rule.
done

# Start the TCP/IP server.
# If this script is called a second time, ncat will terminate immediately since
# the port will already be in use.

ncat -k -l $TCP_PORT < $SERIAL_PORT > $SERIAL_PORT)&

