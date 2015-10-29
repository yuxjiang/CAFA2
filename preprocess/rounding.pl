#!/usr/bin/perl -w
use strict;
use List::Util qw(max);

#
#   Rounds the score to 2 significant figures
#   
# Usage
# -----
#
#   rounding.pl <input file> <output file>
#
# -------------
# Yuxiang Jiang (yuxjiang@indiana.edu)
# Department of Computer Science and Informatics
# Indiana University Bloomington
# Last modified: Sun 24 Aug 2014 10:13:10 PM EDT

my ($ifile, $ofile, @scores);

$ifile = $ARGV[0];
$ofile = $ARGV[1];

open(FIN, "<", $ifile) or die "\nERROR: cannot open $ifile: $!\n";
open(FOUT, ">", $ofile) or die "\nERROR: cannot open $ofile: $!\n";

while (my $running = <FIN>) {
    if ($running =~/^(T|EFI)[0-9]+\s+(GO|HP):[0-9]{7}\s+\d+\.\d+\s*\r?\n$/) {
        my $score = $running;
        $score =~ s/.*(\d+\.\d+)\s*\r?\n/$1/;
        $score = sprintf("%.2f", $score);
        if ($score != 0.00) {
            $running =~ s/(.*)(\d+\.\d+)\s*\r?(\n)/$1$score$3/;
            print FOUT $running;
        }
    } else {
        $running =~ s/\r?\n/\n/;
        print FOUT $running;
    }
}

close FIN or die "ERROR: $!\n";
close FOUT or die "ERROR: $!\n";
