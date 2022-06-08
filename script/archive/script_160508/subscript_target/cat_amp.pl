#! /usr/local/bin/perl -w
use strict;

my @files = @ARGV;
my @coef1;
my @coef2;
my @coef3;
my @coef4;

foreach my $file ( @files ) {
	open IN, '<', $file || die "cannot open $!";
	my $line = 0;
	my $std;
	while (<IN>) {
		$line++;
		s/[\r\n]//g;
		my $coef1 = $_;
		$std = $coef1 if ( $line == 1 );
		my $coef2 = $coef1 / $std;
		
		push(@coef1, $coef2) if ( $line == 1 );
		push(@coef2, $coef2) if ( $line == 2 );
		push(@coef3, $coef2) if ( $line == 3 );
		push(@coef4, $coef2) if ( $line == 4 );
	}
	close(IN);
}

print join(",", @coef1) . "\n";
print join(",", @coef2) . "\n";
print join(",", @coef3) . "\n";
print join(",", @coef4) . "\n";
