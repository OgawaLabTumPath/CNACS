#! /usr/local/bin/perl -w
use strict;

open IN, '<', $ARGV[0] || die "cannot open $!";

my %color = (
	"gneg" => "\"#FFFFFF\"",
	"gpos25" => "\"#BFBFBF\"",
	"gpos50" => "\"#7F7F7F\"",
	"gpos75" => "\"#404040\"",
	"gpos100" => "\"#000000\"",
	"gvar" => "\"#000000\"",
	"stalk" => "\"#BFBFBF\"",
	"acen" => "\"#8B0000\""
);

while (<IN>) {
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	print join("\t", @curRow[ 0 .. 2 ]) . "\t" . $color{$curRow[4]} . "\n";
}
close(IN);
