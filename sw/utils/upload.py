#!/usr/bin/env python3

import serial
import sys

ser = serial.Serial('/dev/ttyUSB0', 4800)

ser.write('1'.encode())

file = open(sys.argv[1], 'rb');
sw = file.read();
file.close()

zeros = bytes(65536-len(sw))

print("sending data ...")

ser.write(sw)
ser.write(zeros)

print("OK")

while True:
    print(ser.readline().decode(), end='')

ser.close()
