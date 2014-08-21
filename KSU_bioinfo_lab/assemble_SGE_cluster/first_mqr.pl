#!/usr/bin/perl
##################################################################################
#
#	USAGE: perl first_mqr.pl [bnx directory] [reference] [p-value Threshold]
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
use lib '/homes/bioinfo/bioinfo_software/perl_modules/lib/perl5/';
use File::Basename; # enable maipulating of the full path
#use Statistics::LineFit;
# use List::Util qw(max);
# use List::Util qw(sum);
##################################################################################
##############                 get arguments                    ##################
##################################################################################
my $bnx_dir=$ARGV[0];
my $ref=$ARGV[1];
my $T = $ARGV[2];
sub edit_file
{
    my $filename = $_[0];
    my $filename_adj = $_[1];
    my $replacement_bpp = $_[2];
    my $sub_ref=`/homes/bioinfo/bioinfo_software/bionano/tools/RefAligner -f -i $filename -merge -bnx -bpp $replacement_bpp -o $filename_adj -maxthreads 16`;
    return $sub_ref;
}
##################################################################################
##############      generate first Molecule Quality Reports     ##################
##################################################################################
my @files_to_remove; # list of BNX files to remove after spliting
unless (opendir(DIR, "${bnx_dir}"))
{
	print "can't open ${bnx_dir}\n"; # open directory full of .bnx files
	next;
}
my $bpp = "${bnx_dir}/bpp_list.txt";
open (BPP, ">", $bpp) or die "Can't open $bpp!\n";
while (my $file = readdir(DIR))
{
	next if ($file =~ m/^\./); # ignore files beginning with a period
	next if ($file !~ m/\.bnx$/); # ignore files not ending with a period
    my (${filename}, ${directories}, ${suffix}) = fileparse($file,'\..*');
    opendir(SUBDIR, "${bnx_dir}/${filename}") or die "can't open ${bnx_dir}/${filename}!\n"; # open subdirectory full of .bnx files
    unless (opendir(SUBDIR, "${bnx_dir}/${filename}"))
    {
        print "can't open ${bnx_dir}/${filename}!\n"; # open subdirectory full of .bnx files
        next;
    }
    ####################################################################
    ##############  create list of adjusted BNX files ##################
    ####################################################################
    open (BNX_LIST, '>', "${bnx_dir}/${filename}_adj_bnx_list.txt") or die "can't open ${bnx_dir}/${filename}_adj_bnx_list.txt \n"; #create list of adj BNXs
    ####################################################################
    ##############    for each split BNX adjust bpp   ##################
    ####################################################################
    while (my $subfile = readdir(SUBDIR))
    {
        next if ($subfile =~ m/^\./); # ignore files beginning with a period
        next if ($subfile !~ m/\.bnx$/); # ignore files not ending with .bnx
        next if ($subfile =~ m/_adj\.bnx$/); # ignore files that have been adjusted
        next if ($subfile =~ m/_q\.bnx$/); # ignore files that have been adjusted
        my (${subfilename}, ${subdirectories}, ${subsuffix}) = fileparse($subfile,'\..*');
        ####################################################################
        ###### run refaligner for flowcell molecule quality report  ########
        ####################################################################
        my $run_ref=`/homes/bioinfo/bioinfo_software/bionano/tools/RefAligner -i ${bnx_dir}/${filename}/$subfile -o ${bnx_dir}/${filename}/${subfilename} -T ${T} -ref ${ref} -bnx -nosplit 2 -BestRef 1 -M 5 -biaswt 0 -Mfast 0 -FP 1.5 -FN 0.15 -sf 0.2 -sd 0.2 -A 5 -res 3.5 -resSD 0.7 -outlier 1e-4 -endoutlier 1e-4 -minlen 100 -minsites 5 -maxthreads 16 -randomize 1 -subset 1 10000`;
        print "$run_ref";
        ####################################################################
        ##############  remove excess files and find new bpp ###############
        ####################################################################
        my $split_file="${bnx_dir}/${filename}/${subfilename}.err";
        unless (open (ERR, '<',"$split_file"))
        {
            print "can't open $split_file!\n";
            next;
        }
        
        my $new_bpp;
        while (<ERR>)
        {
            if (eof)
            {
                my @values=split/\t/;
                $values[5] =~ s/\s+//g;
                $new_bpp=$values[5];
                print BPP "${bnx_dir}/${filename}/${subfilename}.err\t$new_bpp\n";
                
            }
        }
        ###########################################################################
        ##     (rewrite bpp) these default values will be used for stretch     ####
        ###########################################################################
        my $adjusted = edit_file("${bnx_dir}/${filename}/${subfilename}.bnx","${bnx_dir}/${filename}/${subfilename}_adj",$new_bpp);
        print "$adjusted";
        if (-e "${bnx_dir}/${filename}/${subfilename}_adj.bnx")
        {
            print BNX_LIST "${bnx_dir}/${filename}/${subfilename}_adj.bnx\n"; # print name of adj BNX
        }
        ####################################################################
        ########          Remove unadjusted BNX files                #######
        ####################################################################
        my @extensions = qw ( .err .errbin .map .maprate .xmap _intervals.txt _q.bnx _r.cmap .bnx );
        for my $ext (@extensions)
        {
        	`rm ${bnx_dir}/${filename}/${subfilename}${ext}`;
        }
        
    }
    
}

print "done\n";


