#!/bin/bash
echo "---------------------Start c3po---------------------"
c3poPath=$1
uartPath=$2
cmd=$3
echo "c3po path:$c3poPath"
echo "uart path:$uartPath"
echo "cmd:$cmd"
expect -c "  
	set timeout 20;
	spawn time $c3poPath $uartPath;
	expect {
		\"]\" { send $cmd }
	};
	expect {
		\"]\" { send \"quit\r\"; exp_continue }
	};
	"
echo "---------------------End c3po------------------------" 