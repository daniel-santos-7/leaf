#!/usr/bin/env python3

import serial
import sys

ser = serial.Serial('/dev/ttyUSB0', 9600)

ser.write('1'.encode())

file = open(sys.argv[1], 'rb');
sw = file.read();
file.close()

zeros = bytes(65536-len(sw))

ser.write(sw)
ser.write(zeros)

while True:
    print(ser.readline().decode(), end='')

ser.close()