#!/usr/bin/perl

use bytes;

select(STDOUT); $|++;

read(STDIN, $buf, 2);
read(STDIN, $buf, 8000);

print chr(0).chr(224);
print $buf;
print chr(0) x 192;

