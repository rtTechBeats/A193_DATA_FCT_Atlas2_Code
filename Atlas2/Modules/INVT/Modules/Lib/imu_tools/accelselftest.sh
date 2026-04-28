#!/bin/bash
echo "---------------------Start Query Chip ID---------------------"
c3poPath=$1
uartPath=$2
echo "c3po path:$c3poPath"
echo "uart path:$uartPath"
expect -c "
	set timeout 20;
	spawn time $c3poPath $uartPath;
	expect {
		\"]\" { send \"imu selftest accel\r\" }
	};
	expect {
		\"imu:ok\" { send \"quit\r\"; exp_continue }
		\"imu:failed\" { send \"quit\r\"; exp_continue }
	};
	"
echo "---------------------End Query Chip ID------------------------"