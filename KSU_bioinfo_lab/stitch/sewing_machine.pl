#!/usr/bin/perl
###############################################################################
#
#	USAGE: perl sewing_machine.pl
#
#  Created by Jennifer Shelton 5/05/15
#
# DESCRIPTION: Iteratively super scaffolds genome FASTA file with BioNano genome maps using stitch.pl. The pipeline runs alignments with default and relaxed parameters.
# If you are using this as part of the assemble_XeonPhi pipeline the parameter `-b` is the directory with the "contigs" subdirectory created for the "best" assembly.
# REQUIREMENTS: Requires BNGCompare from https://github.com/i5K-KINBRE-script-share/BNGCompare in your home directory. Also requires BioPerl. Also requires RefAligner. Install BioNano scripts and executables in `~/scripts` and `~/tools` directories respectively. Follow the Linux installation instructions in the "2.5.1 IrysSolve server RefAligner and Assembler" section of http://www.bnxinstall.com/training/docs/IrysViewSoftwareInstallationGuide.pdf to install RefAligner.
#
# Example: perl sewing_machine.pl [options]
#
###############################################################################
use strict;
use warnings;
use Term::ANSIColor;
use File::Basename; # enable manipulating of the full path
use Getopt::Long;
use Pod::Usage;
#####################################################################
########################  Default variables  ########################
#####################################################################
# Full path of the directory of the best assembly without trailing slash (e.g. /home/bionano/bionano/Dros_psue_2014_012/default_t_100 )
my $fasta = ""; # (e.g. /home/bionano/bionano/Trib_cast_0002_final/GCF_000227135_wrapped.fasta)
my $reference_maps = ""; #(e.g. /home/bionano/bionano/Trib_cast_0002_final/GCF_000227135_wrapped_BbvCI.cmap)
my $enzyme= ""; # space separated list that can include BspQI BbvCI BsrDI bseCI (e.g. BspQI)
my $f_con="20"; # default value
my $f_algn="40"; # default value
my $s_con="15"; # default value
my $s_algn="90"; # default value
my $T = 1e-8; # default value
my $neg_gap = 20000; # default value
my $project=""; # no spaces, slashes or characters other than underscore (e.g. Trib_cast_0002)
# Use either both "$out" and "$genome_maps":
my $genome_maps = ''; # add assembled cmap path here if it is not in the "refineFinal1" subdirectory within the "contigs" subdirectory of the best assembly directory
my $out =''; # no trailing slash (e.g. /home/bionano/bionano/Trib_cast_0002_final)
# Or "$best_dir":
my $best_dir =''; # no trailing slash (e.g. /home/bionano/bionano/Trib_cast_0002_final)
#################################################################################
##############         Print informative message               ##################
#################################################################################
print "###########################################################\n";
print "#  sewing_machine.pl Version 1.0.2                        #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 5/05/15                    #\n";
print "#  github.com/i5K-KINBRE-script-share/Irys-scaffolding    #\n";
print "#  perl sewing_machine.pl -help # for usage/options       #\n";
print "#  perl sewing_machine.pl -man # for more details         #\n";
print "###########################################################\n";
#########################################################################
########################  End Default variables  ########################
#########################################################################
my $man = 0;
my $help = 0;
my $version = 0;
my $refaligner_dir = '~/tools'; # default path without trailing slash
my $maxmem = 256; # maximum memory in Gbytes


GetOptions (
    'help|?' => \$help,
    'version' => \$version,
    'man' => \$man,
    'p|proj:s' => \$project,
    'e|enzyme:s' => \$enzyme,
    'f|fasta:s' => \$fasta,
    'r|ref_maps:s' => \$reference_maps,
    'f_con|fc:f' => \$f_con,
    'f_algn|fa:f' => \$f_algn,
    's_con|sc:f' => \$s_con,
    's_algn|sa:f' => \$s_algn,
    't|p-value_T:f' => \$T,
    'n|neg_gap:f' => \$neg_gap,
    'o|out_dir:s' => \$out,
    'g|genome_maps:s' => \$genome_maps,
    'b|best_dir:s' => \$best_dir,
    'a|aligner_dir:s' => \$refaligner_dir,
    'x|maxmem:i' => \$maxmem
)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
if ($version)
{
    print "sewing_machine.pl Version 1.0.0\n";
    exit;
}
my $dirname = dirname(__FILE__);
unless (($best_dir) || (($out) && ($genome_maps)))
{
    die "Either specify option -b / --best_dir or both options -o / --out_dir and -g / --genome_maps.\n"; # report missing required variables
}
die "Option -p or --proj not specified.\n" unless $project; # report missing required variables
die "Option -e or --enzyme not specified.\n" unless $enzyme; # report missing required variables
die "Option -f or --fasta not specified.\n" unless $fasta; # report missing required variables
die "Option -r or --ref_maps not specified.\n" unless $reference_maps; # report missing required variables
###########################################################
#          Get genome map CMAP file (fullpath)
###########################################################
my $genome_map_cmap;
unless($genome_maps)
{
    my @genome_map_cmaps = glob("${best_dir}/contigs/*_refineFinal1/*_REFINEFINAL1.cmap");
    for my $file (@genome_map_cmaps)
    {
        if (-f $file)
        {
            $genome_map_cmap = $file;
        }
    }
}
else
{
    $genome_map_cmap = $genome_maps;
}
###########################################################
#                Get/create output directory
###########################################################
unless($out)
{
    my @outs = glob("${best_dir}/..");
    for my $path (@outs)
    {
        $out = $path;
    }
    
}
else
{
    unless (-d $out)
    {
        mkdir($out) or die "Can't create $out: $!";
    }
}
###########################################################
#          Sanity check Default variables section
###########################################################
unless(( -f $fasta) && ( -f $reference_maps) && (-f $genome_map_cmap))
{
      die "File paths passed as arguments or added to the the \"Default variables\" section of sewing_machine.pl are not valid. Remember to add all required flags and values to your command or copy the sewing_machine.pl script into your assembly working directory and update required variables for project in \"Default variables\" section. Run \"perl sewing_machine.pl -help\" for mor details.\n";
}
unless($enzyme =~ /(BspQI|BbvCI|BsrDI|bseCI)/)
{
    die "Enzymes passed as arguments or listed in the \"Default variables\" section of sewing_machine.pl are not valid. Valid entries would be a space separated list that includes one or more of the following options \"BspQI BbvCI BsrDI bseCI\" ( e.g. -e \"BspQI BbvCI\" or -e \"BspQI\"). Remember to add all required flags and values to your command or copy the sewing_machine.pl script into your assembly working directory and update required variables for project in \"Default variables\" section. Run \"perl sewing_machine.pl -help\" for mor details.\n";
}
my %alignment_parameters;
my @alignments = qw/default_alignment relaxed_alignment/;
###########################################################
#                  Default alignments
###########################################################
$alignment_parameters{'default_alignment'} ="-FP 0.8 -FN 0.08 -sf 0.20 -sd 0.10";
###########################################################
#                  Relaxed alignments
###########################################################
$alignment_parameters{'relaxed_alignment'} ="-FP 1.2 -FN 0.15 -sf 0.10 -sd 0.15";

my (${genome_map_filename}, ${genome_map_directories}, ${genome_map_suffix}) = fileparse($genome_map_cmap,qr/\.[^.]*/); # directories has trailing slash
my (${filename}, ${directories}, ${suffix}) = fileparse($fasta,qr/\.[^.]*/); # directories has trailing slash
my $alignment_log_file = "${out}/analysis_alignment_log.txt";
open (my $alignment_log, ">", $alignment_log_file) or die "Can't open $alignment_log_file: $!";
my $stitch_log_file = "${out}/analysis_stitch_log.txt";
open (my $stitch_log, ">", $stitch_log_file) or die "Can't open $stitch_log_file: $!";
for my $stringency (@alignments)
{
    unless(mkdir "${out}/$stringency")
    {
        print "Unable to create ${out}/$stringency\n";
    }
    ###########################################################
    #                         Align
    ###########################################################
    print "Running first alignments and comparison for $stringency stringency...\n";
    print $alignment_log "Running first alignments and comparison for $stringency stringency...\n";
    my $align = `${refaligner_dir}/RefAligner -i ${genome_map_cmap} -ref $reference_maps -o ${out}/${stringency}/${filename}_to_${genome_map_filename} -res 2.9 $alignment_parameters{$stringency} -extend 1 -outlier 1e-4 -endoutlier 1e-2 -deltaX 12 -deltaY 12 -xmapchim 14 -T $T -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 1 -hash -hashdelta 50 -mres 1e-3 -insertThreads 4 -nosplit 2 -biaswt 0 -indel -rres 1.2 -f -maxmem ${maxmem}`;
    print $alignment_log "$align";
    ###########################################################
    #                 Get most metrics
    ###########################################################
    my $comparison_metrics_temp_file = "${out}/${filename}_BNGCompare_temp.csv";
    open (my $comparison_metrics, ">>", $comparison_metrics_temp_file) or die "Can't open $comparison_metrics_temp_file: $!";
    print $comparison_metrics "$stringency :\n";
    close($comparison_metrics);
    my $xmap_alignments = `perl ${dirname}/../../../BNGCompare/BNGCompare.pl -f $fasta -r $reference_maps -q ${genome_map_cmap} -x ${out}/${stringency}/${filename}_to_${genome_map_filename}.xmap -o $comparison_metrics_temp_file`;
    print $xmap_alignments;
    ###########################################################
    #                      Flip xmap
    ###########################################################
    my $flip =  `perl ${dirname}/flip_xmap.pl ${out}/${stringency}/${filename}_to_${genome_map_filename}.xmap ${out}/${stringency}/${genome_map_filename}_to_${filename}`;
    print $flip;
    ###########################################################
    #                 Get flipped metrics
    ###########################################################
    my $flip_align =  `perl ~/BNGCompare/xmap_stats.pl -x ${out}/${stringency}/${genome_map_filename}_to_${filename}.flip -o $comparison_metrics_temp_file`;
    print "$flip_align";
    ###########################################################
    #                       Stitch1
    ###########################################################
    my $stitch_num=1;
    my $failed = 0;
    print "Running iteration of stitch number ${stitch_num}...\n";
    print $stitch_log "Running iteration of stitch number ${stitch_num}...\n";
    my $stitch_dir = "${out}/${stringency}/stitch${stitch_num}";
    unless(mkdir $stitch_dir)
    {
        print "Unable to create $stitch_dir\n";
    }
    my $stitch_out =  `perl ${dirname}/stitch.pl -r ${out}/${stringency}/${filename}_to_${genome_map_filename}_q.cmap -x ${out}/${stringency}/${genome_map_filename}_to_${filename}.flip -f $fasta -o $stitch_dir/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_1 --f_con ${f_con} --f_algn ${f_algn} --s_con ${s_con} --s_algn ${s_algn}`;
    my $agp_list_file = "${out}/$stringency/agp_list.txt";
    open (my $agp_list, ">", $agp_list_file) or die "Can't open $agp_list_file: $!";
    ###########################################################
    #              Make filtered xmap
    ###########################################################
    my $make_filtered = `perl ${dirname}/get_passing_xmap.pl -f ${out}/${stringency}/stitch${stitch_num}/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${stitch_num}_all_filtered.xmap -o ${out}/${stringency}/${filename}_to_${genome_map_filename}.xmap`;
    print $make_filtered;
    ###########################################################
    #    Remove stitch directory if no scaffolds were made
    ###########################################################
    if ($stitch_out !~ /Super_scaffold_.*: Scaffolding molecule = .*/)
    {
        my $remove_failed_directory = `rm -r $stitch_dir`;
        print $remove_failed_directory;
        $failed = 1;
    }
    else
    {
        ###########################################################
        #               Add new output to AGP list
        ###########################################################
        print $agp_list "$stitch_dir/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${stitch_num}_superscaffold.agp\n";
        ###########################################################
        #              Print log of stitch
        ###########################################################
        print "$stitch_out";
        print $stitch_log "$stitch_out";
#        /home/bionano/bionano/Dros_psue_2014_012_tuesday/default_alignment/stitch1/Dros_psue_2014_012_20_40_15_90_1_all_filtered.xmap

    }
    ###########################################################
    #                    Iterate stitch
    ###########################################################
    while ($failed == 0)
    {
        ++$stitch_num;
        print "Running iteration of stitch number ${stitch_num}...\n";
        print $stitch_log "Running iteration of stitch number ${stitch_num}...\n";
        my $out_dir="${out}/${stringency}/stitch${stitch_num}/";
        my $previous_stitch= ${stitch_num} - 1;
        my $old_out_dir="${out}/${stringency}/stitch${previous_stitch}/";
        #Make CMAP
        my $make_cmap = `perl ${dirname}/../assemble_XeonPhi/third-party/fa2cmap_multi.pl -v -i ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold.fasta -e ${enzyme}`;
#        print $make_cmap;
        ###########################################################
        #                       Align scripts
        ###########################################################
        unless(mkdir $out_dir)
        {
            print "Unable to create $out_dir\n";
        }
        my $iter_xmap_alignments = `${refaligner_dir}/RefAligner -i ${genome_map_cmap} -ref ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold*.cmap -o ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_to_${genome_map_filename} -res 2.9 $alignment_parameters{$stringency} -extend 1 -outlier 1e-4 -endoutlier 1e-2 -deltaX 12 -deltaY 12 -xmapchim 14 -T $T -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 1 -hash -hashdelta 50 -mres 1e-3 -insertThreads 4 -nosplit 2 -biaswt 0 -indel -rres 1.2 -f -maxmem ${maxmem}`;
        print $alignment_log "$iter_xmap_alignments";
        ###########################################################
        #                       Flip xmap
        ###########################################################
        my $iter_flip_align = `perl ${dirname}/flip_xmap.pl ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_to_${genome_map_filename}.xmap ${out_dir}${genome_map_filename}_to_${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}`;
        print $iter_flip_align;
        ###########################################################
        #                      Call stitch
        ###########################################################
        my $iter_stitch_out = `perl ${dirname}/stitch.pl -r ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_to_${genome_map_filename}_q.cmap -x ${out_dir}${genome_map_filename}_to_${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}.flip -f ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold.fasta -o ${out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${stitch_num} --f_con ${f_con} --f_algn ${f_algn} --s_con ${s_con} --s_algn ${s_algn}`;
        ###########################################################
        #    Remove stitch directory if no scaffolds were made
        ###########################################################
        if ($iter_stitch_out !~ /Super_scaffold_.*: Scaffolding molecule = .*/)
        {
            my $remove_failed_directory = `rm -r $out_dir`;
            print $remove_failed_directory;
            $failed = 1;
            ###########################################################
            #                 Get super scaffold metrics
            ###########################################################
            my $superscaffold_metrics =  `perl ~/BNGCompare/N50.pl ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold.fasta $comparison_metrics_temp_file`;
            print $superscaffold_metrics;
            my $collapse_agp = `perl ${dirname}/collapse_agp.pl -a $agp_list_file`;
            print $collapse_agp;
            ###########################################################
            #                 Remove intermediate directories
            ###########################################################
            if (${previous_stitch} > 1)
            {
                my $highest_intermediate_stitch = ${previous_stitch} - 1;
                for my $former_stitch_num (1..${highest_intermediate_stitch})
                {
                    my $former_out_dir="${out}/${stringency}/stitch${former_stitch_num}/";
                    if (-d $former_out_dir)
                    {
                        my $remove_intermediate = `rm -r $former_out_dir`;
                        print $remove_intermediate;
                    }
                }
            }
        }
        else
        {
            ###########################################################
            #               Add new output to AGP list
            ###########################################################
            print $agp_list "$out_dir/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${stitch_num}_superscaffold.agp\n";
            ###########################################################
            #              Print log of stitch
            ###########################################################
            print "$iter_stitch_out";
            print $stitch_log "$iter_stitch_out";
        }
        
    }
}
###########################################################
#                 Refine BNGCompare file
###########################################################
my $comparison_metrics_file = "${out}/${filename}_BNGCompare.csv";
my $comparison_metrics_temp_file = "${out}/${filename}_BNGCompare_temp.csv";
my $refineCSV = `perl ~/BNGCompare/refine_comparison.pl $comparison_metrics_temp_file $comparison_metrics_file`;
print "$refineCSV ";

print "Done iterating stitch and generating comparisons of BioNano genome maps and in silico maps\n";
#################################################################################
##############                  Documentation                   #################
#################################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME

sewing_machine.pl - iteratively super scaffold genome FASTA files with BioNano genome maps using stitch.pl. The pipeline runs alignments with default and relaxed parameters.
 
If you are using this as part of the assemble_XeonPhi pipeline the parameter `-b` is the directory with the "contigs" subdirectory created for the "best" assembly.
 
=head1 REQUIREMENTS

Requires BNGCompare from https://github.com/i5K-KINBRE-script-share/BNGCompare in your home directory. Also requires BioPerl. Also requires RefAligner. Install BioNano scripts and executables in `~/scripts` and `~/tools` directories respectively. Follow the Linux installation instructions in the "2.5.1 IrysSolve server RefAligner and Assembler" section of http://www.bnxinstall.com/training/docs/IrysViewSoftwareInstallationGuide.pdf to install RefAligner.

=head1 UPDATES

B<sewing_machine.pl Version 1.0.1>

Replaced "${dirname}/../stitch/" with "${dirname}/" now that sewing_machine.pl is in the "stitch" subdirectory. Also changed "~/BNGCompare/BNGCompare.pl" to "${dirname}/../../../BNGCompare/BNGCompare.pl" for systems where the user does not want to clone to the home directory.
 
B<sewing_machine.pl Version 1.0.2>
 
Added optional flag to change RefAligner directory from the default "~/tools". Also added ability to change "-maxmem" flag for RefAligner which specifies maximum memory in Gbytes (default 256).
 

=head1 USAGE

perl sewing_machine.pl [options]

Documentation options:

    -help    brief help message
    -man	    full documentation


Required options:

    -o	     output directory
    -g	     genome map CMAP file
    -p	     project
    -e	     enzyme
    -f	     scaffold (reference) FASTA
    -r	     reference (in silico map) CMAP file

Required options (for assemble_XeonPhi pipeline):
 
    -b	     best assembly directory (replaces -o and -g)
 
System options:

    -a	     The directory for RefAligner
    -x	     Maximum Memory in Gbytes

Filtering options:

    --f_con	 first minimum confidence score (default = 20)
    --f_algn	 first minimum % of possible alignment (default = 40)
    --s_con	 second minimum confidence score (default = 15)
    --s_algn	 second minimum % of possible alignment (default = 90)
    --n	         minimum negative gap length allowed (default = 20000 bp)
    -T	         RefAligner p-value threshold (default = 1e-8)

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.
 

=item B<-o, --out_dir>
 
Path of the user selected output directory without trailing slash (e.g. -o ~/stitch_out ).
 
=item B<-g, --genome_maps>

Path of the CMAP file containing genome maps assembled from single molecule maps (e.g. -g ~/Irys-scaffolding/KSU_bioinfo_lab/sample_output_directory/BioNano_consensus_cmap/ESCH_COLI_1_2015_000_STRICT_T_150_REFINEFINAL1.cmap ).
 
=item B<-p, --project>

The project name with no spaces, slashes or characters other than underscore (e.g. -p Esch_coli_1_2015_000).

=item B<-e, --enzyme>
 
A space separated list of the enzymes used to label the molecules and to in silico nick the sequence-based FASTA file. They can include BspQI BbvCI BsrDI bseCI (e.g. -e BspQI). If multiple enzymes were used enclose the list with quotes (e.g. -e "BspQI BbvCI").

=item B<-f, --fasta>

Path of the FASTA file that will be super-scaffolded based on alignment to the assembled genome maps. It is preferable to use the scaffold FASTA rather than the contigs. Many contigs will not be long enough to align.
 
=item B<-r, --r_cmap>

The reference CMAP produced from your sequence FASTA file.
 
=item B<-b, --best_dir>

Path of the user selected directory of the "best" assembly without trailing slash (e.g. ~/Esch_coli_1_2015_000/default_t_100 ). This parameter replaces -o and -g when using the assemble_XeonPhi pipeline.
 
=item B<--f_con, --fc>

The minimum confidence score for alignments for the first round of filtering. This should be the most stringent, highest, of the two scores (default = 20).

=item B<--f_algn, --fa>

The minimum PAT, or minimum percent of the full potential length of the alignment allowed, for the first round of filtering. This should be lower than the setting for the second round of filtering (default = 40).

=item B<--s_con, --sc>

The minimum confidence score for alignments for the second round of filtering. This should be the less stringent, lowest, of the two scores (default = 15).

=item B<--s_algn, --sa>

The minimum PAT, or percent of the full potential length of the alignment allowed, for the second round of filtering. This should be higher than the setting for the first round of filtering (default = 90).

=item B<-n, --neg_gap>

Allows user to adjust minimum negative gap length allowed (default = 20000 bp).
 
=item B<-t, --p-value_T>

The RefAligner p-value threshold (default = 1e-8). Can use -T as low as 1e-6 for small bacterial genomes or up to 1e-9 or 1e-10 for large genomes (> 1G).
 
=item B<-a, --aligner_dir>

The directory for RefAligner (without a trailing slash). (default = ~/tools )

=item B<-x, --maxmem>

Maximum Memory in Gbytes (default 256)

=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

The script outputs an XMAP filtered and unfiltered alignments of the original in silico maps to the genome maps and an alignment of the super scaffold in silico maps to the genome maps. Copy the entire output directory to a windows machine before importing into IrysView (in the IrysView "comparisons" window).

The script also lists summary metrics in a csv file.

In the same csv file, scaffolds that have alignments passing the user-defined length and confidence thresholds that align over less than 60% of the total length possible are listed. These may represent mis-assembled scaffolds.

In the same csv file, high quality but overlaping alignments in a csv file are listed. These may be candidates for further assembly using the overlaping contigs and paired end reads.

The super scaffold FASTA is non-redundant (i.e. no scaffold was used twice) from the user-provided scaffold FASTA file and the filtered XMAP. If two scaffolds overlap on the superscaffold then a 100 "n" gap is used as a spacer between them (provided the negative gap length is larger than the minimum negative gap length). If adjacent scaffolds do not overlap on the super-scaffold than the distance between the begining and end of each scaffold reported in the XMAP is used as the gap length. If a scaffold has two high quality alignments the longest alignment is selected. If both alignments are equally long the alignment with the highest confidence is selected.

The script also outputs contigs, an agp, and a bed file of contigs within superscaffolds from the final super scaffold fasta file.


B<QUICK START:>

Follow instructions in https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/blob/master/KSU_bioinfo_lab/stitch/sewing_machine_LAB.md

=cut
