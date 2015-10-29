#!/usr/bin/perl -w
use strict;
use List::Util qw(max);

#
#   Linearly maps the score to the given interval (0.00, 1.00]
#   
# Usage
# -----
#
#   linear_mapping.pl <input file> <output file>
#
# -------------
# Yuxiang Jiang (yuxjiang@indiana.edu)
# Department of Computer Science and Informatics
# Indiana University Bloomington
# Last modified: Mon 25 Aug 2014 09:35:15 AM EDT

my ($ifile, $ofile, @scores);

$ifile = $ARGV[0];
$ofile = $ARGV[1];

open(FIN, "<", $ifile) or die "\nERROR: cannot open $ifile: $!\n";
open(FOUT, ">", $ofile) or die "\nERROR: cannot open $ofile: $!\n";

while (<FIN>) {
    if (/.*\s+\d+\.\d+\s*\r?\n$/) {
        # record score
        s/.*\s+(\d+\.\d+)\s*\r?\n$/$1/;
        push(@scores, $_);
    }
}

my $max_score = max( @scores );

printf "max score: %.2f\n", $max_score;

seek(FIN, 0, 0); # return to the beginning of the input file

while (my $running = <FIN>) {
    if ($running =~/.*\s+\d+\.\d+\s*\r?\n$/) {
        my $score = $running;
        $score =~ s/.*\s+(\d+\.\d+)\s*\r?\n/$1/;
        $score = sprintf("%.2f", $score / $max_score);
        if ($score ge 0.005) {
            $running =~ s/(.*\s+)(\d+\.\d+)\s*\r?(\n)/$1$score$3/;
            print FOUT $running;
        }
    } else {
        $running =~ s/\r?\n/\n/;
        print FOUT $running;
    }
}

close FIN or die "ERROR: $!\n";
close FOUT or die "ERROR: $!\n";
