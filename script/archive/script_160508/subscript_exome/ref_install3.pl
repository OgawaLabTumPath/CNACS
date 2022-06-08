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
	$used{$key} = $_;
}
close(ALL_DEPTH);


# Define targeted regions
my %line2chr1;
my %line2start1;
my %line2end1;
my %line2chr2;
my %line2start2;
my %line2end2;
my $line = 0;

open TARGET, '<', $ARGV[2] || die "cannot open $!";
while (<TARGET>) {
	$line++;
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	my $probe_num = $curRow[-1] + $curRow[-2];
	if ( $probe_num < 5 ) {
		$line2chr1{$line} = $curRow[0];
		$line2start1{$line} = $curRow[1];
		$line2end1{$line} = $curRow[2];
	} elsif ( $curRow[-2] < 5 ) {
		$line2chr2{$line} = $curRow[0];
		$line2start2{$line} = $curRow[1];
		$line2end2{$line} = $curRow[2];
	}
}
close(TARGET);


# Filtering based on depth
open DEPTH_INFO, '<', $ARGV[0] || die "cannot open $!";
my $depth_mean_lower = $ARGV[4];
my $depth_mean_upper = $ARGV[5];
my $depth_coefvar_upper = $ARGV[6];
my %line2probe;
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
	
	my $targeted1 = 0;
	my $target_line1;
	foreach my $tmp_line1 ( sort keys %line2chr1 ) {
		next if ( $curRow[0] ne $line2chr1{$tmp_line1} );
		my $overlap_idx = ( $curRow[1] - $line2start1{$tmp_line1} + 1 ) * ( $curRow[2] - $line2end1{$tmp_line1} - 1 );
		if ( $overlap_idx < 0 ) {
			$targeted1 = 1;
			$target_line1 = $tmp_line1;
			last;
		}
	}
	
	my $targeted2 = 0;
	my $target_line2;
	if ( $targeted1 == 0 ) {
		foreach my $tmp_line2 ( sort keys %line2chr2 ) {
			next if ( $curRow[0] ne $line2chr2{$tmp_line2} );
			my $overlap_idx = ( $curRow[1] - $line2start2{$tmp_line2} + 1 ) * ( $curRow[2] - $line2end2{$tmp_line2} - 1 );
			if ( $overlap_idx < 0 ) {
				$targeted2 = 1;
				$target_line2 = $tmp_line2;
				last;
			}
		}
	}
	
	
	if ( $targeted1 == 1 ) {
		if ( ( $mean < $depth_mean_lower ) || ( $mean > $depth_mean_upper ) || ( $coefvar > 2 * $depth_coefvar_upper ) ) {
			$removed{$key} = 1;
		} else {
			if ( defined $line2probe{$target_line1} ) {
				$line2probe{$target_line1}++;
			} else {
				$line2probe{$target_line1} = 1;
			}
		}
	} elsif ( $targeted2 == 1 ) {
		if ( ( $mean < $depth_mean_lower ) || ( $mean > $depth_mean_upper ) || ( $coefvar > 1.5 * $depth_coefvar_upper ) ) {
			$removed{$key} = 1;
		} else {
			if ( defined $line2probe{$target_line2} ) {
				$line2probe{$target_line2}++;
			} else {
				$line2probe{$target_line2} = 1;
			}
		}
	} else {
		if ( ( $mean < $depth_mean_lower ) || ( $mean > $depth_mean_upper ) || ( $coefvar > $depth_coefvar_upper ) ) {
			$removed{$key} = 1;
		}
	}
}
close(DEPTH_INFO);


# Output of filtered information on gene probes
open DEPTH_INFO, '<', $ARGV[0] || die "cannot open $!";

while (<DEPTH_INFO>) {
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	my $key = $curRow[0] . "\t" . $curRow[1];
	next if ( defined $used{$key} );
	
	unless ( defined $removed{$key} ) {
		$used{$key} = $curRow[0] . ':' . $curRow[1] . '-' . $curRow[2] . "\t" . join("\t", @curRow[ 5 .. $#curRow ]);
	}
}
close(DEPTH_INFO);


open ALL_DEPTH, '>', $ARGV[1] || die "cannot open $!";
print ALL_DEPTH $header;
foreach my $pos ( sort chrpos keys %used ) {
	print ALL_DEPTH $used{$pos} . "\n";
}
close(ALL_DEPTH);


# Number of remaining probes in target regions
open TARGET, '<', $ARGV[2] || die "cannot open $!";
open TARGET_PROBE, '>', $ARGV[3] || die "cannot open $!";
$line = 0;

while (<TARGET>) {
	$line++;
	s/[\r\n]//g;
	print TARGET_PROBE $_ . "\t";
	
	my @curRow = split(/\t/, $_);
	my $probe_num = $curRow[-1] + $curRow[-2];
	if ( $probe_num < 5 ) {
		if ( defined $line2probe{$line} ) {
			my $added = $line2probe{$line} - $probe_num;
			print TARGET_PROBE $added . "\n";
		} else {
			print TARGET_PROBE '0' . "\n";
		}
	} else {
		print TARGET_PROBE '0' . "\n";
	}
}
close(TARGET);
close(TARGET_PROBE);


# sort accoding to chromosome and position
sub chrpos {
	my @posa = split("\t", $a);
	my @posb = split("\t", $b);
	
	$posa[0] =~ s/chr//g;
	$posb[0] =~ s/chr//g;
	
	$posa[0] =~ s/X/23/g;
	$posb[0] =~ s/X/23/g;
	
	$posa[0] =~ s/Y/24/g;
	$posb[0] =~ s/Y/24/g;
	
	$posa[0] =~ s/M/25/g;
	$posb[0] =~ s/M/25/g;
	
	if ($posa[0] > $posb[0]) {
		return 1;
	} elsif ($posa[0] < $posb[0]) {
		return -1;
	} else {
		if ($posa[1] > $posb[1]) {
			return 1;
		} else {
			return -1;
		}
	}
}
