#!/bin/bash

ioMap=$1
ip=$2

expect -c "  
	set timeout -1;
	spawn time scp $ioMap root@$ip:/mix/addon/test_function/;
	expect {
		\"password: \" { send \"123456\r\" }
		\"yes/no\" { send \"yes\r\"; exp_continue }
	};
	expect 100%
	expect eof
	"