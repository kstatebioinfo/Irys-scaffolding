#!/usr/bin/perl
##################################################################################
#   Script reads from a list of maps to flip from a txt file (one CMmap id per line) and creates a CMap with the requested flips.
#	USAGE: perl FlipByID.pl [cmap] [list of maps to flip]
#
#  Created by jennifer shelton
#
# to test a CMAP run "RefAligner -i FILENAME.cmap -o outfile  -bnx"
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
use File::Basename;
use Tie::File;
##################################################################################
##############                   Get arguements                 ##################
##################################################################################
my $cmap = $ARGV[0];
my $flip_list = $ARGV[1];
##################################################################################
##############         find cmap id of all maps to flip         ##################
##################################################################################
my %flips;
open (FLIP, '<',$flip_list) or die "Can't open $flip_list!\n";
while (<FLIP>)
{
    chomp;
    $flips{$_} = 1;
}
##################################################################################
##############                   create output files            ##################
##################################################################################
my (${filename}, ${directories}, ${suffix}) = fileparse($cmap,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
my $out =  "${directories}${filename}_flip.cmap";
print "${directories}${filename}_flip.cmap\n";
open (OUT_CMAP, '>',$out) or die "Can't open $out!\n";
my $line; # row in cmap to reverse
my @reversed; # array of one molecule to be reversed
##################################################################################
############## Open cmap as an array to flip maps in the flip list ###############
##################################################################################
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
            $cmaps[5]=$cmaps[1] - $cmaps[5] - 0.1; #(because the BioNano maps start at 20? This no longer matters but now 0.1 seems to be added on in the last place??)
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
                    my $new_columns;
                    my ($CMapId,$ContigLength,$NumSites,$SiteID,$LabelChannel,$Position,$StdDev,$Coverage,$Occurrence,$GmeanSNR,$lnSNRsd,$SNR_count);
                    #                    my @columns = split ("\t",$reversed[$i]);
                    #### Unless this is the original of the map ######
                    unless ($i == $#reversed)
                    {
                        ($CMapId,$ContigLength,$NumSites,$SiteID,$LabelChannel,$Position,$StdDev,$Coverage,$Occurrence,$GmeanSNR,$lnSNRsd,$SNR_count) = split ("\t",$reversed[$i]);
                    }
                    #### for the original start of the map ######
                    #                    if ($i == 0)
                    #                    {
                    
                    #                    }
                    #### for the original end of the map ######
                    if ($i == $#reversed)
                    {
                        next;
                    }
                    #### for the original second to end of the map ######
                    if ($i == ($#reversed -1))
                    {
                        $Position = 20;
                        #                        print OUT_CMAP "$CMapId\t$ContigLength\t$NumSites\t$j\t$LabelChannel\t20\t$StdDev\t$Coverage\t$Occurrence\t$GmeanSNR\t$lnSNRsd\t$SNR_count";
                        #                        ++$j;
                    }
                    #### for all other maps ######
                    $new_columns = "$CMapId\t$ContigLength\t$NumSites\t$j\t$LabelChannel\t$Position\t$StdDev\t$Coverage\t$Occurrence\t$GmeanSNR\t$lnSNRsd\t$SNR_count";
                    print OUT_CMAP "$new_columns";
                    if ($i == 0)
                    {
                        my $final_site = $j + 1;
                        my $last_columns = "$CMapId\t$ContigLength\t$NumSites\t$final_site\t0\t$ContigLength\t0\.0\t1\t1\n";
                        print OUT_CMAP "$last_columns";
                        #                        6	325166.0	50	51	0	325166.0	0.0	1	1
                        #                        4	500651.5	71	72	0	500651.5	0.0	1	1
                        #                        1	1264931.4	204	205	0	1264931.4	0.0	1	1
                    }
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
