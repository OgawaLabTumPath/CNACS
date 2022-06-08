#! /usr/local/perl -w
use strict;

open IN, '<', $ARGV[0] || die "cannot open $!";
my $sample = $ARGV[1];

while (<IN>) {
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	my $name = $curRow[0];
	$name =~ s/\"//g;
	if ( $name eq $sample ) {
		unless ( $curRow[1] =~ /^[FM]$/ ) {
			print "Sex should be 'F' or 'M'.\n";
		} else {
			print $curRow[1];
			last;
		}
	}
}
close(IN);
