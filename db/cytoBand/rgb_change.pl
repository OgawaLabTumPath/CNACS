#! /usr/local/bin/perl -w
use strict;

open IN, '<', $ARGV[0] || die "cannot open $!";
while (<IN>) {
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	my $color;
	if ( $curRow[3] =~ /000000/ ) {
		$color = "0\t0\t0";
	} elsif ( $curRow[3] =~ /404040/ ) {
		$color = "0.25\t0.25\t0.25";
	} elsif ( $curRow[3] =~ /7F7F7F/ ) {
		$color = "0.5\t0.5\t0.5";
	} elsif ( $curRow[3] =~ /BFBFBF/ ) {
		$color = "0.75\t0.75\t0.75";
	} elsif ( $curRow[3] =~ /FFFFFF/ ) {
		$color = "1\t1\t1";
	} elsif ( $curRow[3] =~ /8B0000/ ) {
		$color = "0.55\t0\t0";
	} else {
		next;
	}
	
	print join("\t", @curRow[ 0 .. 2 ]) . "\t" . $color . "\n";
}
close(IN);
