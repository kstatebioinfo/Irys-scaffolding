#!/usr/bin/perl
#################################################################################
#
#	USAGE: perl flip_xmap.pl <XMAP> <output basename
#
#  Created by jennifer shelton
#
#################################################################################
use strict;
use warnings;
use File::Basename; # enable maipulating of the full path
# use List::Util qw(max);
# use List::Util qw(sum);
#use Getopt::Long;
#use Pod::Usage;
#################################################################################
##############                correct xmap order               ##################
#################################################################################
#print "Correcting xmap order ...\n";
my $xmap = $ARGV[0];
my $output_basename =$ARGV[1];
open (XMAP, "<", $xmap) or die "Can't open $xmap: $!";
my $sort_xmap = "${output_basename}.flip";
open (SORT_XMAP,">", $sort_xmap) or die "Can't open $sort_xmap: $!";
my @xmap_table;
my $XmapEntryID_new = 1;
while (<XMAP>) #make array of contigs from the customer and a hash of their lengths
{
	if ($_ =~ /^#/)
	{
		print SORT_XMAP;
	}
    elsif ($_ !~ /^#/)
	{
        chomp;
        unless (/^\s*$/)
        {
            my ($XmapEntryID,$QryContigID,$RefContigID,$QryStartPos,$QryEndPos,$RefStartPos,$RefEndPos,$Orientation,$Confidence,$HitEnum) =split ("\t");
            
            my ($QryContigID_new,$RefContigID_new,$QryStartPos_new,$QryEndPos_new,$RefStartPos_new,$RefEndPos_new,$Orientation_new,$Confidence_new,$HitEnum_new);

            if ($Orientation eq '-')
            {
                $RefStartPos_new = $QryEndPos;
                $RefEndPos_new = $QryStartPos;
                $QryStartPos_new = $RefEndPos;
                $QryEndPos_new = $RefStartPos;
                
            }
            else
            {
                $RefStartPos_new = $QryStartPos;
                $RefEndPos_new = $QryEndPos;
                $QryStartPos_new = $RefStartPos;
                $QryEndPos_new = $RefEndPos;
                
            }
#            ($XmapEntryID_new,$QryContigID_new,$RefContigID_new,$RefStartPos_new,$RefEndPos_new,$Orientation_new,$Confidence_new,$HitEnum)
            my @xmap=("1",$RefContigID,$QryContigID,$QryStartPos_new,$QryEndPos_new,$RefStartPos_new,$RefEndPos_new,$Orientation,$Confidence,"NA");
            s/\s+//g foreach @xmap;
            push (@xmap_table, [@xmap]);
        }
        
	}
}
###################
#h [0]XmapEntryID	[1]QryContigID	[2]RefContigID	[3]QryStartPos	[4]QryEndPos	[5]RefStartPos	[6]RefEndPos	[7]Orientation	[8]Confidence	[9]HitEnum
my @xmap_table_sorted = sort {
    
    $a->[2] <=> $b->[2] || # the result is -1,0,1 ...
    $a->[5] <=> $b->[5]    # so [1] when [0] is same
    
} @xmap_table;
for my $i ( 0 .. $#xmap_table_sorted )
{
    $xmap_table_sorted[$i][0]=$i;
}

print SORT_XMAP (join("\t", @$_), "\n") for @xmap_table_sorted;
close (SORT_XMAP);

