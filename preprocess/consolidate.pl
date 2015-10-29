#!/usr/bin/perl -w
use strict;
#
#   Consolidate raw CAFA submission files
#   
#   Note that those submission files must be put into the required file 
#   hierarchy as stated in readme.txt
#
# Usage
# -----
#
#   1. Run this script under the CHECK mode first, and manually correct file 
#      headers according to the generated log file.
#
#   2. Make sure that all files have consistent file header BEFORE running 
#      NORMAL mode.
#
#   Check mode:
#   -----
#   consolidate.pl -c <submission dir> <output dir>
#
#   Normal mode:
#   ------
#   consolidate.pl <submission dir> <output dir>
#
# -------------
# Yuxiang Jiang (yuxjiang@indiana.edu)
# Department of Computer Science and Informatics
# Indiana University Bloomington
# Last modified: Wed 05 Nov 2014 11:56:20 AM EST

my ($mode, $sub_dir, $out_dir);

if ($ARGV[0] eq "c" || $ARGV[0] eq "-c") {
    $mode = 1;
    $sub_dir = $ARGV[1];
    $out_dir = $ARGV[2];
} else {
    $mode = 0;
    $sub_dir = $ARGV[0];
    $out_dir = $ARGV[1];
}

my (@teams, $team);

open(my $log, ">", $out_dir . "log.txt") or die "\nERROR: cannot open $out_dir" . "log.txt: $!\n";
open(my $tbl, ">", $out_dir . "table.txt") or die "\nERROR: cannot open $out_dir" . "log.txt $!\n";

print $tbl "external ID\tinternal ID\n";

@teams = <$sub_dir*>;

my $internal_count = 0; # internal ID count

my $error_bit = 0;
            
mkdir($out_dir . "PASSED");
mkdir($out_dir . "FAILED");

foreach $team (@teams) {
    my $team_ID = substr($team, rindex($team, '/') + 1);

    print "\nProcessing folder $team_ID ...\n";

    my (@models, $model);

    @models = <$team/*>;
    foreach $model (@models) {
        my $model_ID = substr($model, rindex($model, '/') + 1);
        my $ext_ID = "$team_ID-$model_ID";

        # generate internal ID
        # internal ID format M[0-9]{3}, padding with 0
        $internal_count = $internal_count + 1;
        my $int_ID = sprintf("M%03d", $internal_count);

        my (@mfiles, $mfile);
        my ($running, @author_tags, @model_tags);

        @mfiles = <$model/*>;
        if ($mode == 0) { # NORMAL mode
            my $fname = $out_dir . "PASSED/" . $int_ID;
            open(FOUT, ">", $fname) or die "\nERROR: cannot open $fname: $!\n";
            foreach $mfile (@mfiles) {
                print "\tconsolidating $mfile ...\n";

                open(FIN, "<", "$mfile") or die "\nERROR: cannot open $mfile: $!.\n";

                my $raw_fname = substr($mfile, rindex($mfile, '/') + 1);
                my $flog_name = $out_dir . "FAILED/" . $int_ID . "_" . $raw_fname;
                open(FLOG, ">", $flog_name) or die "\nERROR: cannot open $flog_name: $!\n";

                # filter prediction lines
                while (<FIN>) {
                    if (/^(T|EFI)[0-9]+\s+(GO|HP):[0-9]{7}\s+(1\.0{2}|0\.[0-9]{2})\s*\r?\n$/) {
                        s/\r?\n/\n/;
                        print FOUT $_;
                    } else {
                        print FLOG $_;
                    }
                }
                close FLOG or die "ERROR: $!\n";

                # check the log file, remove it if all passed
                my $fine = 1;
                open(FLOG, "<", $flog_name) or die" \nERROR: cannot open $flog_name: $!\n";
                while (<FLOG>) {
                    $fine = 0 unless (/AUTHOR.*/ || /KEYWORDS.*/ || /MODEL.*/ || /ACCURACY.*/ || /END.*/);
                }
                close FLOG or die "ERROR: $!\n";
                unlink $flog_name if ($fine == 1);

                close FIN or die "ERROR: $!\n";
            }
            close FOUT or die "ERROR: $!\n";

            # update external -> internal ID table
            print $tbl "$ext_ID\t$int_ID\n";
            
        }
        if ($mode == 1) { # CHECK mode
            foreach $mfile (@mfiles) {
                open(FIN, "<", "$mfile") or die "\nERROR: cannot open $mfile: $!.\n";

                # collect and check header information
                # AUTHOR, MODEL, KEYWORDS

                $running = <FIN>;
                if ($running =~ /^AUTHOR\s/) {
                    $running =~ s/AUTHOR\s*(\w+([\s-]+\w+)*)\s*\r?\n/$1/; # remove tailing DOS/Unix style cartridge return
                    #print "$mfile | author [$running]\n";
                    push(@author_tags, $running);
                } else {
                    print $log "ERROR: incorrect AUTHOR field in $mfile\n";
                    $error_bit = 1;
                }

                $running = <FIN>;
                if ($running =~ /^MODEL\s*[123]\s*$/) {
                    $running =~ s/MODEL\s*([123])\s*\r?\n/$1/; # remove tailing DOS/Unix style cartridge return
                    push(@model_tags, $running);
                } else {
                    print $log "ERROR: incorrect MODEL field in $mfile\n";
                    $error_bit = 1;
                }

                close FIN or die "ERROR: $!\n";
            }

            if ($error_bit == 1) {
                print "$ext_ID: A format error occurred!\n";
                $error_bit = 0; # clear error bit
                next;
            }

            # check header consistency
            my $running_author = $author_tags[0];
            my $running_model  = $model_tags[0];
            for (my $i = 1; $i < @author_tags; $i++) {
                if ($author_tags[$i] ne $running_author) {
                    print $log "ERROR: inconsistent AUTHOR field for $ext_ID\n";
                    $error_bit = 1;
                }
                if ($model_tags[$i] ne $running_model) {
                    print $log "ERROR: inconsistent MODEL field for $ext_ID\n";
                    $error_bit = 1;
                }
            }

            # print out check result
            if ($error_bit == 0) {
                print "$ext_ID: CHECK PASSED! | AUTHOR [$author_tags[0]] | MODEL [$model_tags[0]]\n";
            } else {
                print "$ext_ID: An error occurred during consistency check!\n";
                $error_bit = 0; # clear error bit
                next;
            }
        }
    }
}

close $tbl or die "$tbl: $!\n";
close $log or die "$log: $!\n";
