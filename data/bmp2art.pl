#!/usr/bin/perl

use bytes;

read(STDIN, $buf, 2);
read(STDIN, $buf, 8000);

select(STDOUT); $|++;
print chr(0).chr(32);
print $buf;
print chr(1)x1000;
print chr(240);
print chr(0).chr(34).chr(0).chr(0).chr(0).chr(34);

# 9009 bytes

