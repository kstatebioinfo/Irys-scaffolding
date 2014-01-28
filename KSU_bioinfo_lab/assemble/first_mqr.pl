#!/bin/perl
##################################################################################
#   
#	USAGE: perl first_mqr.pl [bnx directory] [reference]
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
use File::Basename; # enable maipulating of the full path
# use List::Util qw(max);
# use List::Util qw(sum);
##################################################################################
##############                 get arguments                    ##################
##################################################################################
my $bnx_dir=$ARGV[0];
my $ref=$ARGV[1];
sub edit_file
{
    my $filename = $_[0];
    my $filename_adj = $_[1];
    my $replacement_bpp = $_[2];
    my $sub_ref=`~/tools/RefAligner -i $filename -merge -bnx -bpp $replacement_bpp -o $filename_adj`;
    return $sub_ref;
}
##################################################################################
##############      generate first Molecule Quality Reports     ##################
##################################################################################
opendir(DIR, "${bnx_dir}") or die "can't open ${bnx_dir}!\n"; # open directory full of .bnx files
while (my $file = readdir(DIR))
{
	next if ($file =~ m/^\./); # ignore files beginning with a period
	next if ($file !~ m/\.bnx$/); # ignore files not ending with a period
    my (${filename}, ${directories}, ${suffix}) = fileparse($file,'\..*');
    opendir(SUBDIR, "${bnx_dir}/${filename}") or die "can't open ${bnx_dir}/${filename}!\n"; # open directory full of .bnx files
    my (@x,@y);
    while (my $subfile = readdir(SUBDIR))
    {
        next if ($subfile =~ m/^\./); # ignore files beginning with a period
        next if ($subfile !~ m/\.bnx$/); # ignore files not ending with a period
        my (${subfilename}, ${subdirectories}, ${subsuffix}) = fileparse($subfile,'\..*');
        ####################################################################
        ##############           run refaligner           ##################
        ####################################################################
        my $run_ref=`~/tools/RefAligner -i ${bnx_dir}/${filename}/$subfile -o ${bnx_dir}/${filename}/${subfilename} -bnx -minsites 5 -minlen 150 -BestRef 1 -M 2 -ref ${ref}`;
        print "$run_ref";
        ####################################################################
        ##############  remove excess files and find new bpp ###############
        ####################################################################
        `rm ${bnx_dir}/${filename}/${subfilename}_r.cmap`;
        `rm ${bnx_dir}/${filename}/${subfilename}_q.cmap`;
        `rm ${bnx_dir}/${filename}/${subfilename}.map`;
        `rm ${bnx_dir}/${filename}/${subfilename}.xmap`;
        my $split_file="${bnx_dir}/${filename}/${subfilename}.err";
        open (ERR, '<',"$split_file") or die "can't open $split_file !\n";
        $split_file =~ "(${bnx_dir}/${filename}/${filename})(.*)(.err)";
        push (@x,$2);
        my $new_bpp;
        while (<ERR>)
        {
            if (eof)
            {
                my @values=split/\t/;
                $values[5] =~ s/\s+//g;
                $new_bpp=$values[5];
                push (@y,$new_bpp);
            }
        }
        ###########################################################################
        ## (rewrite bpp) these default values will be used if regression fails ####
        ###########################################################################
        my $first_edit=edit_file("${bnx_dir}/${filename}/${subfilename}.bnx","${bnx_dir}/${filename}/${subfilename}_adj.bnx",$new_bpp);
        print "$first_edit\n";
    }
    ####################################################################
    ########  do regression use predicted value of y if exists  ########
    ####################################################################
    use Statistics::LineFit;
    my $threshold=.2;
    my $validate=1;
    my $lineFit = Statistics::LineFit->new($validate); # $validate = 1 -> Verify input data is numeric (slower execution)
    $lineFit->setData(\@x, \@y) or die "Invalid regression data\n";
    if (defined $lineFit->rSquared()
        and $lineFit->rSquared() > $threshold) # if rSquared is defined and above the threshold rewrite the bpp using predicted Y-values
    {
        my ($intercept, $slope) = $lineFit->coefficients();
        print "Slope: $slope  Y-intercept: $intercept\n";
        for (my $i = 0; $i <= $#x; $i++)
        {
            ####################################################################
            ##############    rewrite bpp if regression fits    ################
            ####################################################################
            my $predicted_y = ($x[$i] * $slope)+$intercept;
            edit_file("${bnx_dir}/${filename}/${filename}$x[$i].bnx","${bnx_dir}/${filename}/${subfilename}$x[$i]_adj.bnx","$predicted_y")
        }
    }

}


