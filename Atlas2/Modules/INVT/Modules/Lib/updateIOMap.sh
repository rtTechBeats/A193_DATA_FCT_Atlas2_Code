#!/bin/bash

ip=$1
ioMap=$2

echo $ip,$ioMap

expect -c "  
	set timeout -1;
	spawn time scp /vault/build/slot_$slot/out.bin root@169.254.1.$ip:/mix/dut_firmware/ch$ch/;
	expect {
		\"password: \" { send \"123456\r\" }
		\"yes/no\" { send \"yes\r\"; exp_continue }
	};
	expect 100%
	expect eof
	"
expect -c "  
	set timeout -1;
	spawn time scp /vault/build/slot_$slot/firmware.md5 root@169.254.1.$ip:/mix/dut_firmware/ch$ch/;
	expect {
		\"password: \" { send \"123456\r\" }
		\"yes/no\" { send \"yes\r\"; exp_continue }
	};
	expect 100%
	expect eof
	"
