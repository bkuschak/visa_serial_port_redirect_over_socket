# Run this script on the remote machine that wants to connect to the power
# supply over TCP/IP.
#
# Assume a Raspberry Pi at 192.168.2.238 is connected to the power supply via
# USB serial port and is running the /bin/start_visa_redirect.sh script that
# was started via udev rule.

import pyvisa as visa

# Open the power supply using the serial port redirected over TCP/IP socket.
rm = visa.ResourceManager()
ps = rm.open_resource('TCPIP0::192.168.2.238::6000::SOCKET')  
ps.timeout = 2000   # msec                                  
ps.read_termination = '\n'                                         
write_termination = '\n'                                           
ps.clear()                                                         

# Identify the device.
# Expect: HEWLETT-PACKARD,E3632A,0,1.2-5.0-1.0
print(ps.query('*IDN?'))
