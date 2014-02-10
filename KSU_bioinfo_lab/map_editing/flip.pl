#!/bin/perl
###############################################################################
#   Script reads from a list of maps to flip from a txt file (one CMmap id per line) and creates a CMap with the requested flips.
#	USAGE: perl flip.pl [cmap] [list of maps to flip]
#
#  Created by jennifer shelton
#
###############################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
use File::Basename;
use Tie::File;
###############################################################################
##############                Get arguements                 ##################
###############################################################################
my $cmap = $ARGV[0];
my $flip_list = $ARGV[1];
###############################################################################
##############        find cmap id of all maps to flip       ##################
###############################################################################
my %flips;
open (FLIP, '<',$flip_list) or die "Can't open $flip_list!\n";
while (<FLIP>)
{
    chomp;
    $flips{$_} = 1;
}
###############################################################################
##############                   create output files         ##################
###############################################################################
my (${filename}, ${directories}, ${suffix}) = fileparse($cmap,'\..*'); 
my $out =  "${directories}${filename}_flip.cmap";
print "${directories}${filename}_flip.cmap\n";
open (OUT_CMAP, '>',$out) or die "Can't open $out!\n";
my $line; # row in cmap to reverse
my @reversed; # array of one molecule to be reversed
###############################################################################
########### Open cmap as an array to flip maps in the flip list ###############
###############################################################################
tie my @file, 'Tie::File', "$cmap" or die $!; # Access the lines of a disk file via a Perl array
for my $linenr (0 .. $#file)
{
    ###################################################
    ##############    Print headers     ###############
    ###################################################
    if ($file[$linenr] =~ /^#/)
    {
        print OUT_CMAP "$file[$linenr]\n";
    }
    ###################################################
    ####    Print unflipped and flipped maps     ######
    ###################################################
    else
    {
        chomp($file[$linenr]);
        my @cmaps=split ("\t",$file[$linenr]);
        s/\s+//g foreach @cmaps;
        ###################################################
        ####    Flip map if it should be reversed    ######
        ###################################################
        if ($flips{$cmaps[0]}) 
        {
            #### rewrite label position ######
            $cmaps[5]=$cmaps[1] - $cmaps[5] + 20; #(because the BioNano maps start at 20?)
            $line = '';
            #### concatinate altered line ######
            for my $i (0..$#cmaps)
            {
                if ($i == $#cmaps)
                {
                    $line = $line."$cmaps[$i]\n";
                }
                else
                {
                    $line = $line."$cmaps[$i]\t";
                }
            }
            ####### add to array ######
            push (@reversed,$line);
            ###################################################
            ####  Check if next row is on the same map   ######
            ###################################################
            my @nexts = split ("\t",$file[$linenr + 1]);
            #### print in reverse if the cmap id changes ######
            if ((!$nexts[0])||($nexts[0] != $cmaps[0]))
            {
                my $j=1;
                for my $i (reverse 0..$#reversed)
                {
                    $reversed[$i] =~ s/(.*\t.*\t)(.*)(\t.*\t.*\t.*\t.*\t.*\n)/$1$j$3/; #print site id in reverse order
                    print OUT_CMAP "$reversed[$i]";
                    ++$j;
                }
                undef @reversed; # empty the array for the next map to be flipped
            }
            
        }
        ###################################################
        ####   Print map as-is for non-flipped maps  ######
        ###################################################
        else
        {
            print OUT_CMAP "$file[$linenr]\n"; # print non-reversed
        }
        
        
    }
}
untie @file;   # all done
