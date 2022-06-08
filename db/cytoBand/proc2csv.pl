#! /usr/local/bin/perl -w
use strict;

open IN, '<', $ARGV[0] || die "cannot open $!";
while (<IN>) {
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	my $chr = $curRow[0];
	$chr =~ s/^chr//;
	if ( $chr eq 'X' ) {
		$chr = 23;
	} elsif ( $chr eq 'Y' ) {
		$chr = 24;
	} elsif ( $chr =~ /[\D]/ ) {
		next;
	}
	
	my $start = int($curRow[1]/100000) / 10;
	my $end = int($curRow[2]/100000) / 10;
	print $chr . "," . $start . "," . $end . "," . join(",", @curRow[3 .. $#curRow]) . "\n";
}
close(IN);
