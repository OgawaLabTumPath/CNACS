#! /usr/local/bin/perl -w
use strict;

# Define already adopted probes
open ALL_DEPTH, '<', $ARGV[1] || die "cannot open $!";
my %used;
my $header = <ALL_DEPTH>;
while (<ALL_DEPTH>) {
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	my @info = split(/:/, $curRow[0]);
	my @pos = split(/-/, $info[1]);
	my $key = $info[0] . "\t" . $pos[0];
	$used{$key} = 1;
}
close(ALL_DEPTH);


# Define targeted regions
my %id2chr;
my %id2start;
my %id2end;
my $id = 0;

open TARGET, '<', $ARGV[2] || die "cannot open $!";
while (<TARGET>) {
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	my $probe_num = $curRow[-1];
	if ( $probe_num < 5 ) {
		$id++;
		$id2chr{$id}   = $curRow[0];
		$id2start{$id} = $curRow[1];
		$id2end{$id}   = $curRow[2];
	}
}
close(TARGET);
my $target_num = $id;


# Filtering based on depth
open DEPTH_INFO, '<', $ARGV[0] || die "cannot open $!";
my $depth_mean_lower = $ARGV[4];
my $depth_mean_upper = $ARGV[5];
my $depth_coefvar_upper = $ARGV[6];
my %id2probe;
my %removed;

while (<DEPTH_INFO>) {
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	my $key = $curRow[0] . "\t" . $curRow[1];
	my $mean = $curRow[3];
	my $coefvar = $curRow[4];
	if ( $coefvar eq 'NA' ) {
		$removed{$key} = 1;
		next;
	}
	
	my $targeted = 0;
	my $target_id;
	foreach my $cur_id ( 1 .. $target_num ) {
		next if ( $curRow[0] ne $id2chr{$cur_id} );
		my $overlap_idx = ( $curRow[1] - $id2start{$cur_id} + 1 ) * ( $curRow[2] - $id2end{$cur_id} - 1 );
		if ( $overlap_idx < 0 ) {
			$targeted = 1;
			$target_id = $cur_id;
			last;
		}
	}
	
	if ( $targeted == 1 ) {
		if ( ( $mean < $depth_mean_lower ) || ( $mean > $depth_mean_upper ) || ( $coefvar > 1.5 * $depth_coefvar_upper ) ) {
			$removed{$key} = 1;
		} elsif ( $targeted == 1 ) {
			if ( defined $id2probe{$target_id} ) {
				$id2probe{$target_id}++;
			} else {
				$id2probe{$target_id} = 1;
			}
		}
	} else {
		if ( ( $mean < $depth_mean_lower ) || ( $mean > $depth_mean_upper ) || ( $coefvar > $depth_coefvar_upper ) ) {
			$removed{$key} = 1;
		}
	}
}
close(DEPTH_INFO);


# Output of filtered information on probes
open DEPTH_INFO, '<', $ARGV[0] || die "cannot open $!";
open ALL_DEPTH, '>>', $ARGV[1] || die "cannot open $!";

while (<DEPTH_INFO>) {
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	my $key = $curRow[0] . "\t" . $curRow[1];
	next if ( defined $used{$key} );
	
	unless ( defined $removed{$key} ) {
		print ALL_DEPTH $curRow[0] . ':' . $curRow[1] . '-' . $curRow[2] . "\t" . join("\t", @curRow[ 5 .. $#curRow ]) . "\n";
	}
}
close(DEPTH_INFO);
close(ALL_DEPTH);


# Number of remaining probes in target regions
open TARGET, '<', $ARGV[2] || die "cannot open $!";
open REMAINING, '>', $ARGV[3] || die "cannot open $!";
my $line = 0;
$id = 0;

while (<TARGET>) {
	$line++;
	s/[\r\n]//g;
	print REMAINING $_ . "\t";
	
	my @curRow = split(/\t/, $_);
	my $probe_num = $curRow[-1];
	if ( $probe_num < 5 ) {
		$id++;
		if ( defined $id2probe{$id} ) {
			my $added = $id2probe{$id} - $probe_num;
			print REMAINING $added . "\n";
		} else {
			print REMAINING '0' . "\n";
		}
	} else {
		print REMAINING '0' . "\n";
	}
}
close(TARGET);
close(REMAINING);
