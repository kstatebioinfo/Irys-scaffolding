#!/bin/perl
##################################################################################
#   
#	USAGE: perl first_mqr.pl [bnx directory] [reference] [p-value Threshold]
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
my $T = $ARGV[2];
sub edit_file
{
    my $filename = $_[0];
    my $filename_adj = $_[1];
    my $replacement_bpp = $_[2];
    my $sub_ref=`~/tools/RefAligner -f -i $filename -merge -bnx -bpp $replacement_bpp -o $filename_adj -maxthreads 16`;
    return $sub_ref;
}
##################################################################################
##############      generate first Molecule Quality Reports     ##################
##################################################################################
my @files_to_remove; # list of BNX files to remove after spliting
opendir(DIR, "${bnx_dir}") or die "can't open ${bnx_dir}!\n"; # open directory full of .bnx files
while (my $file = readdir(DIR))
{
	next if ($file =~ m/^\./); # ignore files beginning with a period
	next if ($file !~ m/\.bnx$/); # ignore files not ending with a period
    my (${filename}, ${directories}, ${suffix}) = fileparse($file,'\..*');
    opendir(SUBDIR, "${bnx_dir}/${filename}") or die "can't open ${bnx_dir}/${filename}!\n"; # open directory full of .bnx files
    my (@x,@y);
    ####################################################################
    ##############        create regression log       ##################
    ####################################################################
    open (REGRESSION_LOG, '>', "${bnx_dir}/${filename}_regressionlog.txt") or die "can't open ${bnx_dir}/${filename}_regressionlog.txt \n"; #create log for regression
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
        next if ($subfile !~ m/\.bnx$/); # ignore files not ending with a period
        my (${subfilename}, ${subdirectories}, ${subsuffix}) = fileparse($subfile,'\..*');
        ####################################################################
        ###### run refaligner for flowcell molecule quality report  ########
        ####################################################################
        my $run_ref=`~/tools/RefAligner -i ${bnx_dir}/${filename}/$subfile -o ${bnx_dir}/${filename}/${subfilename} -T ${T} -ref ${ref} -bnx -nosplit 2 -BestRef 1 -M 5 -biaswt 0 -Mfast 0 -FP 1.5 -FN 0.15 -sf 0.2 -sd 0.2 -A 5 -S -1000 -res 3.5 -resSD 0.7 -outlier 1e-4 -endoutlier 1e-4 -minlen 150 -minsites 5 -maxthreads 16`;
        print "$run_ref";
        ####################################################################
        ##############  remove excess files and find new bpp ###############
        ####################################################################
        `rm ${bnx_dir}/${filename}/${subfilename}_r.cmap`;
        `rm ${bnx_dir}/${filename}/${subfilename}_q.cmap`;
        `rm ${bnx_dir}/${filename}/${subfilename}.map`;
        `rm ${bnx_dir}/${filename}/${subfilename}.xmap`;
        my $split_file="${bnx_dir}/${filename}/${subfilename}.err";
        open (ERR, '<',"$split_file") or next "can't open $split_file !\n";
        $split_file =~ "(${bnx_dir}/${filename}/${filename}_)(.*)(.err)";
        push (@x,$2);
        print REGRESSION_LOG "$2,";
        my $new_bpp;
        while (<ERR>)
        {
            if (eof)
            {
                my @values=split/\t/;
                $values[5] =~ s/\s+//g;
                $new_bpp=$values[5];
                push (@y,$new_bpp);
                print REGRESSION_LOG "$new_bpp\n";
            }
        }
        ###########################################################################
        ## (rewrite bpp) these default values will be used if regression fails ####
        ###########################################################################
        my $adjusted = edit_file("${bnx_dir}/${filename}/${subfilename}.bnx","${bnx_dir}/${filename}/${subfilename}_adj",$new_bpp);
        print "$adjusted";
        push (@files_to_remove,"${bnx_dir}/${filename}/${subfilename}.bnx");
        print BNX_LIST "${bnx_dir}/${filename}/${subfilename}_adj.bnx\n"; # print name of adj BNX
    }
    ####################################################################
    ########  do regression, use predicted value of y if exists  #######
    ####################################################################
    use Statistics::LineFit;
    my $threshold=.2;
    my $validate=1;
    my $lineFit = Statistics::LineFit->new($validate); # $validate = 1 -> Verify input data is numeric (slower execution)
    $lineFit->setData(\@x, \@y) or next "Invalid regression data\n";
    my $rsquare=$lineFit->rSquared();
    print REGRESSION_LOG "Rsquare: $rsquare \n";
    if (defined $lineFit->rSquared()
        and $lineFit->rSquared() > $threshold) # if rSquared is defined and above the threshold rewrite the bpp using predicted Y-values
    {
        my ($intercept, $slope) = $lineFit->coefficients();
        print REGRESSION_LOG "Slope: $slope  Y-intercept: $intercept\n";
        for (my $i = 0; $i <= $#x; $i++)
        {
            ####################################################################
            ##############    rewrite bpp if regression fits    ################
            ####################################################################
            my $predicted_y = ($x[$i] * $slope)+$intercept;
            my $adjusted = edit_file("${bnx_dir}/${filename}/${filename}_$x[$i].bnx","${bnx_dir}/${filename}/${filename}_$x[$i]_adj","$predicted_y");
            print "$adjusted";
        }
    }

}
####################################################################
########          Remove unadjusted BNX files                #######
####################################################################
for my $remove (@files_to_remove)
{
    `rm $remove`;
}



