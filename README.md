# RS-232 to TCP/IP bridge for old SCPI instruments

Make old instruments with RS-232 SCPI ports accessible over the network.      

Some old instruments, like the Agilent E36xxA family of power supplies, have only RS-232 and GPIB ports for remote control. 
They lack LAN ports for TCP/IP remote control. Use a RaspberryPi or similar SBC as an RS-232 to TCP/IP bridge to make these 
devices accessible over the network.  This method tunnels all the traffic over a TCP socket. pyvisa can then connect to them using 
the ```:SOCKET``` protocol, such as:
                                                                                
```                                                                             
TCPIP0::192.168.2.238::6000::SOCKET                                             
```                                                                             
                                                                                
## Hardware                                                                     
                                                                                
Requirements:                                                                   
                                                                                
- Raspberry Pi or similar with free USB port(s)                                 
- Old SCPI instrument(s) with RS-232 serial comms interface               
- FTDI USB-to-serial adapter(s)                                              
- RS-232 cables                                                  
                                                                                
## Installation                                                                 

Install prerequisites:

```
sudo apt-get install at ncat
```
 
Plug in the FTDI USB serial ports. Do this one at a time and identify the serial numbers, such as FTXQI63U shown below. 
Make note of these serial numbers and which instruments they will connect to. Connect RS-232 cables to the instruments. 
You might possibly need NULL modem cables.

```
$ sudo dmesg |grep -E 'FTDI|SerialNumber'
[    5.338991] usb 1-1.2: Manufacturer: FTDI
[    5.346826] usb 1-1.2: SerialNumber: FTXQI63U
[   25.973981] usbserial: USB Serial support registered for FTDI USB Serial Device
[   25.974567] ftdi_sio 1-1.2:1.0: FTDI USB Serial Device converter detected
[   26.170823] usb 1-1.2: FTDI USB Serial Device converter now attached to ttyUSB0
```

On some systems, serial-getty may automatically be started for serial ports.  If a new getty process is started after 
plugging in the serial port, you will need to disable that behaviour.  Something like this may be needed:

```
sudo systemctl stop serial-getty@ttyUSB0
sudo systemctl disable serial-getty@ttyUSB0
```

Install these files on RaspberryPi.                                                    
                                                                                
```                                                                             
$ sudo cp start_visa_redirect.sh /bin  
$ sudo cp 52-ftdi.rules /etc/udev/rules.d/   
$ sudo chmod +x /bin/start_visa_redirect.sh                                                                                                                                                                                                                                                 
```    

Edit ```/etc/udev/rules.d/52-ftdi.rules```:
- Change the ```ATTR{serial}``` numbers to match the serial numbers of your USB devices. 
- Change the ```SYMLINK``` and ```RUN``` names to something relevant for your equipment. 
- If you want, change the TCP/IP ports from the default 6000 and 6001 to something else.

If your instrument uses something other than 9600-8-n-1, edit ```start_visa_redirect.sh``` and change the baud rate in the stty commmand.

Refresh the udev daemon:

```
$ sudo udevadm control --reload-rules && sudo udevadm trigger
```

The scripts should now start running.  They will log a message to syslog when starting:

```
$ tail /var/log/messages
Jul 13 05:10:24 raspberrypi root: Starting TCP/IP socket on port 6001 for serial port /dev/power_supply_e3631a
```

You should see new processes running:

```
$ ps auxw
root       425  0.0  0.3   3272  1576 ?        SN   05:10   0:00 /bin/bash /bin/start_visa_redirect.sh /dev/power_supply_e3632a 6000
root       429  0.0  0.3   3272  1640 ?        SN   05:10   0:00 /bin/bash /bin/start_visa_redirect.sh /dev/power_supply_e3631a 6001
root       451  0.0  0.6   9392  3020 ?        SN   05:10   0:00 ncat -k -l 6000
root       452  0.0  0.6   9392  3024 ?        SN   05:10   0:00 ncat -k -l 6001
```

Configure the instrument serial port (default is 9600-8-n-1).  Unforunately the DTR/DSR flow control method is unsupported, so we have to be careful when 
sending commands to avoid overflowing the buffers.

## Usage

On the remote computer, use pyvisa to access the instrument.  See example.py for a simple script to query the instrument.  You'll need to edit the IP address in the file to match your Raspberry Pi.

```
$  python example.py
HEWLETT-PACKARD,E3632A,0,1.2-5.0-1.0
```
      
You will have to add a short delay after each command (0.5 second or maybe longer) to avoid overflowing the instrument's buffers. For example:

```
def write(msg):                                                       
    # Communication fails unless we delay after sending each command..      
    ret = instrument.write(msg)                                                
    time.sleep(0.5)                                                         
    return ret    
```

This is not ideal, and it might not work if the network link has variable latency. At least on a LAN, it has worked well enough for me.
Anyone have a better idea?  Maybe rewire the port to connect DTR/DSR flow control lines to RTS/CTS and enable crtscts in stty?

