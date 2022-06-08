#! /usr/local/bin/perl -w
use strict;

# Filtering based on BAF
open BAF_INFO, '<', $ARGV[0] || die "cannot open $!";
open BAF_INFO_FILT, '>', $ARGV[3] || die "cannot open $!";
my $baf_mean_lower = $ARGV[6];
my $baf_mean_upper = $ARGV[7];
my $baf_coefvar_upper = $ARGV[8];

my $header = <BAF_INFO>;
print BAF_INFO_FILT $header;
while (<BAF_INFO>) {
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	my $mean = $curRow[4];
	my $coefvar = $curRow[5];
	next if ( $coefvar eq 'NA' );
	
	print BAF_INFO_FILT $_ . "\n" unless ( ( $mean < $baf_mean_lower ) || ( $mean > $baf_mean_upper ) || ( $coefvar > $baf_coefvar_upper ) || ( $coefvar == 0 ) );
}
close(BAF_INFO);
close(BAF_INFO_FILT);


# Define targeted regions
my %line2chr;
my %line2start;
my %line2end;
my %line2info;
my $line = 0;

open TARGET, '<', $ARGV[2] || die "cannot open $!";
while (<TARGET>) {
	$line++;
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	$line2chr{$line} = $curRow[0];
	$line2start{$line} = $curRow[1];
	$line2end{$line} = $curRow[2];
	$line2info{$line} = $_;
}
close(TARGET);
my $target_num = $line;


# Filtering based on depth
open DEPTH_INFO, '<', $ARGV[1] || die "cannot open $!";
my $depth_mean_lower = $ARGV[9];
my $depth_mean_upper = $ARGV[10];
my $depth_coefvar_upper = $ARGV[11];
my %line2probe;
my %removed;

while (<DEPTH_INFO>) {
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	my $key = $curRow[0] . "\t" . $curRow[2];
	my $mean = $curRow[3];
	my $coefvar = $curRow[4];
	if ( $coefvar eq 'NA' ) {
		$removed{$key} = 1;
		next;
	}
	
	my $targeted = 0;
	my $target_line;
	foreach my $cur_line ( 1 .. $target_num ) {
		next if ( $curRow[0] ne $line2chr{$cur_line} );
		my $overlap_idx = ( $curRow[1] - $line2start{$cur_line} + 1 ) * ( $curRow[2] - $line2end{$cur_line} - 1 );
		if ( $overlap_idx < 0 ) {
			$targeted = 1;
			$target_line = $cur_line;
			last;
		}
	}

	if ( ( $mean < $depth_mean_lower ) || ( $mean > $depth_mean_upper ) || ( $coefvar > $depth_coefvar_upper ) ) {
		$removed{$key} = 1;
	} elsif ( $targeted == 1 ) {
		if ( defined $line2probe{$target_line} ) {
			$line2probe{$target_line}++;
		} else {
			$line2probe{$target_line} = 1;
		}
	}
}
close(DEPTH_INFO);


# Output of filtered information on probes
open DEPTH_INFO, '<', $ARGV[1] || die "cannot open $!";
open ALL_DEPTH, '>>', $ARGV[4] || die "cannot open $!";

while (<DEPTH_INFO>) {
	s/[\r\n]//g;
	my @curRow = split(/\t/, $_);
	my $key = $curRow[0] . "\t" . $curRow[2];
	
	unless ( defined $removed{$key} ) {
		print ALL_DEPTH $curRow[0] . ':' . $curRow[1] . '-' . $curRow[2] . "\t" . join("\t", @curRow[ 5 .. $#curRow ]) . "\n";
	}
}
close(DEPTH_INFO);
close(ALL_DEPTH);

# Number of remaining probes in target regions
open REMAINING, '>', $ARGV[5] || die "cannot open $!";

foreach my $cur_line ( 1 .. $target_num ) {
	print REMAINING $line2info{$cur_line} . "\t";
	if ( defined $line2probe{$cur_line} ) {
		print REMAINING $line2probe{$cur_line} . "\n";
	} else {
		print REMAINING '0' . "\n";
	}
}
close(REMAINING);
