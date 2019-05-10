#!/bin/sh

# bash script that builds the cpld image veri.jam on the ubuntu build server

quartus_map cpld
quartus_fit cpld
quartus_asm cpld
