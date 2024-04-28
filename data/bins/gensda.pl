#!/usr/bin/perl -s

# labouriously reverse engineered

use bytes;
select(STDOUT); $|++;

$template = shift @ARGV;
open(K, $template) || die("can't open template SDA \"$template\": $!\n");

@exclude = split(/,/, $exclude);

@files = grep {
	my $w = $_;
	(scalar(grep { $w eq $_ } @exclude)) ? 0 : 1;
} @ARGV;
@files = sort @files unless ($nosort);

die("no files") if (!scalar(@files));

@cfiles = map {
	my $w = $_;
	$w =~ tr/a-zA-Z/A-Za-z/;
	$w = substr($w.("\0"x16),0,16);
} @files;

read(K, $buf, 535);
print $buf;

print $cfiles[$#cfiles];
print chr(80); # "P"

read(K, $buf, 17);
read(K, $buf, 116);
print $buf;

undef $/;
foreach(@files) {
	open(G, $_) || die("can't open \"$_\": $!\n");
	$buf = <G>;
	close(G);

	print shift @cfiles;
	print chr(80);
	print pack("v", length($buf));
	print $buf;
}
print "\0";

