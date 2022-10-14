#!/bin/bash

stty -F /dev/ttyUSB0 speed 9600 cs8 -cstopb -parenb

echo '1' > /dev/ttyUSB0

cat $1 /dev/zero | head -c64k > /dev/ttyUSB0