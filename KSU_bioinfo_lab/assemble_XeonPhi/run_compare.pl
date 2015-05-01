#!/usr/bin/perl
###############################################################################
#
#	USAGE: perl run_compare.pl
#
#  Created by Jennifer Shelton 2/26/15
#
# DESCRIPTION: # Copy script into assembly working directory and update other variables for project in "Project variables" section or run original script by adding the equivalent flags and values to your command. To do the former cd to the assembly working directory and "cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/run_compare.pl ." and then edit the new version to point to the best asssembly or the best assembly CMAP, etc.
# REQUIREMENTS: Requires BNGCompare from https://github.com/i5K-KINBRE-script-share/BNGCompare in your home directory. Also requires BioPerl.
#
# Example: perl run_compare.pl
#
###############################################################################
use strict;
use warnings;
use Term::ANSIColor;
use File::Basename; # enable manipulating of the full path
use Getopt::Long;
use Pod::Usage;
#####################################################################
########################  Project variables  ########################
#####################################################################
# Full path of the directory of the best assembly without trailing slash (e.g. /home/bionano/bionano/Dros_psue_2014_012/default_t_100 )
my $best_dir =""; # no trailing slash (e.g. /home/bionano/bionano/Trib_cast_0002_final)
my $fasta = ""; # (e.g. /home/bionano/bionano/Trib_cast_0002_final/GCF_000227135_wrapped.fasta)
my $cmap = ""; #(e.g. /home/bionano/bionano/Trib_cast_0002_final/GCF_000227135_wrapped_BbvCI.cmap)
my $enzyme= ""; # space separated list that can include BspQI BbvCI BsrDI bseCI (e.g. BspQI)
my $f_con="20"; # default value
my $f_algn="40"; # default value
my $s_con="15"; # default value
my $s_algn="90"; # default value
my $T = 1e-8; # default value
my $neg_gap = 20000; # default value
my $project=""; # no spaces, slashes or characters other than underscore (e.g. Trib_cast_0002)
my $optional_assembled_cmap = ''; # add assembled cmap path here if it is not in the "refineFinal1" subdirectory within the "contigs" subdirectory of the best assembly directory
##################################################################################
##############         Print informative message                ##################
##################################################################################
print "###########################################################\n";
print colored ("#      WARNING: SCRIPT CURRENTLY UNDER DEVELOPMENT        #", 'bold white on_blue'), "\n";
print "#  run_compare.pl Version 1.0.0                           #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 2/26/15                    #\n";
print "#  github.com/i5K-KINBRE-script-share/Irys-scaffolding    #\n";
print "#  perl run_compare.pl -help # for usage/options          #\n";
print "#  perl run_compare.pl -man # for more details            #\n";
print "###########################################################\n";
#########################################################################
########################  End project variables  ########################
#########################################################################
my $man = 0;
my $help = 0;
my $version = 0;
GetOptions (
    'help|?' => \$help,
    'version' => \$version,
    'man' => \$man,
    'b|best_dir:s' => \$best_dir,
    'p|proj:s' => \$project,
    'e|enzyme:s' => \$enzyme,
    'f|fasta:s' => \$fasta,
    'r|ref:s' => \$cmap,
    'f_con|fc:f' => \$f_con,
    'f_algn|fa:f' => \$f_algn,
    's_con|sc:f' => \$s_con,
    's_algn|sa:f' => \$s_algn,
    't|p-value_T:f' => \$T,
    'n|neg_gap:f' => \$neg_gap,
    'opt_c|optional_assembled_cmap' => \$optional_assembled_cmap
)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
if ($version)
{
    print "run_compare.pl Version 1.0.0\n";
    exit;
}
my $dirname = dirname(__FILE__);
die "Option -b or --best_dir not specified.\n" unless $best_dir; # report missing required variables
die "Option -p or --proj not specified.\n" unless $project; # report missing required variables
die "Option -e or --enzyme not specified.\n" unless $enzyme; # report missing required variables

die "Option -f or --fasta not specified.\n" unless $fasta; # report missing required variables
die "Option -r or --ref not specified.\n" unless $cmap; # report missing required variables


###########################################################
#            Get genome map CMAP file (fullpath)
###########################################################
my $genome_map_cmap;
unless($optional_assembled_cmap)
{
    $genome_map_cmap = `ls ${best_dir}/contigs/*_refineFinal1/*_REFINEFINAL1.cmap`;
    chomp($genome_map_cmap);
}
else
{
    $genome_map_cmap = $optional_assembled_cmap;
}
###########################################################
#          Sanity check project variables section
###########################################################
unless(( -f $fasta) && ( -f $cmap) && (-f $genome_map_cmap))
{
      die "File paths in the \"Project variables\" section of run_compare.pl are not valid. Remember to copy the run_compare.pl script into your assembly working directory and update other variables for project in \"Project variables\" section or add the equivalent flags and values to your command. To do the former cd to the assembly working directory and \"cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/run_compare.pl .\" and then edit the new version to point to the best asssembly or the best assembly CMAP.\n";
}
unless($enzyme =~ /(BspQI|BbvCI|BsrDI|bseCI)/)
{
    die "Enzymes listed in the \"Project variables\" section of run_compare.pl are not valid. Valid entries would be a space separated list that includes one or more of the following options \"BspQI BbvCI BsrDI bseCI\". Remember to copy the run_compare.pl script into your assembly working directory and update other variables for project in \"Project variables\" section or add the equivalent flags and values to your command. To do the former cd to the assembly working directory and \"cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/run_compare.pl .\" and then edit the new version to point to the best asssembly or the best assembly CMAP.\n";
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
my $alignment_log_file = "$best_dir/../analysis_alignment_log.txt";
open (my $alignment_log, ">", $alignment_log_file) or die "Can't open $alignment_log_file: $!";
my $stitch_log_file = "$best_dir/../analysis_stitch_log.txt";
open (my $stitch_log, ">", $stitch_log_file) or die "Can't open $stitch_log_file: $!";
for my $stringency (@alignments)
{
    unless(mkdir "$best_dir/../$stringency")
    {
        print "Unable to create $best_dir/../$stringency\n";
    }
    ###########################################################
    #                         Align
    ###########################################################
    print "Running first alignments and comparison for $stringency stringency...\n";
    print $alignment_log "Running first alignments and comparison for $stringency stringency...\n";
    my $align = `~/tools/RefAligner -i ${genome_map_cmap} -ref $cmap -o ${best_dir}/../${stringency}/${filename}_to_${genome_map_filename} -res 2.9 $alignment_parameters{$stringency} -extend 1 -outlier 1e-4 -endoutlier 1e-2 -deltaX 12 -deltaY 12 -xmapchim 14 -T $T -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 1 -hash -hashdelta 50 -mres 1e-3 -insertThreads 4 -nosplit 2 -biaswt 0 -indel -rres 1.2 -f -maxmem 256`;
    print $alignment_log "$align";
    ###########################################################
    #                 Get most metrics
    ###########################################################
    my $comparison_metrics_file = "${best_dir}/../${filename}_BNGCompare.csv";
    open (my $comparison_metrics, ">>", $comparison_metrics_file) or die "Can't open $comparison_metrics_file: $!";
    print $comparison_metrics "$stringency :\n";
    close($comparison_metrics);
    my $xmap_alignments = `perl ~/BNGCompare/BNGCompare.pl -f $fasta -r $cmap -q ${genome_map_cmap} -x ${best_dir}/../${stringency}/${filename}_to_${genome_map_filename}.xmap -o $comparison_metrics_file`;
    print $xmap_alignments;
    ###########################################################
    #                      Flip xmap
    ###########################################################
    my $flip =  `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/flip_xmap.pl ${best_dir}/../${stringency}/${filename}_to_${genome_map_filename}.xmap ${best_dir}/../${stringency}/${genome_map_filename}_to_${filename}`;
    print $flip;
    ###########################################################
    #                 Get flipped metrics
    ###########################################################
    my $flip_align =  `perl ~/BNGCompare/xmap_stats.pl -x ${best_dir}/../${stringency}/${genome_map_filename}_to_${filename}.flip -o $comparison_metrics_file`;
    print "$flip_align";
    ###########################################################
    #                       Stitch1
    ###########################################################
    my $stitch_num=1;
    my $failed = 0;
    print "Running iteration of stitch number ${stitch_num}...\n";
    print $stitch_log "Running iteration of stitch number ${stitch_num}...\n";
    my $stitch_dir = "$best_dir/../${stringency}/stitch${stitch_num}";
    unless(mkdir $stitch_dir)
    {
        print "Unable to create $stitch_dir\n";
    }
    my $stitch_out =  `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/stitch.pl -r ${best_dir}/../${stringency}/${filename}_to_${genome_map_filename}_q.cmap -x ${best_dir}/../${stringency}/${genome_map_filename}_to_${filename}.flip -f $fasta -o $stitch_dir/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_1 --f_con ${f_con} --f_algn ${f_algn} --s_con ${s_con} --s_algn ${s_algn}`;
    my $agp_list_file = "$best_dir/../$stringency/agp_list.txt";
    open (my $agp_list, ">", $agp_list_file) or die "Can't open $agp_list_file: $!";
    ###########################################################
    #              Make filtered xmap
    ###########################################################
    my $make_filtered = `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/get_passing_xmap.pl -f $best_dir/../${stringency}/stitch1/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_1_all_filtered.xmap -o ${best_dir}/../${stringency}/${filename}_to_${genome_map_filename}.xmap`;
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
        my $out_dir="${best_dir}/../${stringency}/stitch${stitch_num}/";
        my $previous_stitch= ${stitch_num} - 1;
        my $old_out_dir="${best_dir}/../${stringency}/stitch${previous_stitch}/";
        #Make CMAP
        my $make_cmap = `perl ~/bin/fa2cmap_multi.pl -v -i ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold.fasta -e ${enzyme}`;
#        print $make_cmap;
        ###########################################################
        #                       Align scripts
        ###########################################################
        unless(mkdir $out_dir)
        {
            print "Unable to create $out_dir\n";
        }
        my $iter_xmap_alignments = `~/tools/RefAligner -i ${genome_map_cmap} -ref ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold*.cmap -o ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_to_${genome_map_filename} -res 2.9 $alignment_parameters{$stringency} -extend 1 -outlier 1e-4 -endoutlier 1e-2 -deltaX 12 -deltaY 12 -xmapchim 14 -T $T -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 1 -hash -hashdelta 50 -mres 1e-3 -insertThreads 4 -nosplit 2 -biaswt 0 -indel -rres 1.2 -f -maxmem 256`;
        print $alignment_log "$iter_xmap_alignments";
        ###########################################################
        #                       Flip xmap
        ###########################################################
        my $iter_flip_align = `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/flip_xmap.pl ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_to_${genome_map_filename}.xmap ${out_dir}${genome_map_filename}_to_${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}`;
        print $iter_flip_align;
        ###########################################################
        #                      Call stitch
        ###########################################################
        my $iter_stitch_out = `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/stitch.pl -r ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_to_${genome_map_filename}_q.cmap -x ${out_dir}${genome_map_filename}_to_${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}.flip -f ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold.fasta -o ${out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${stitch_num} --f_con ${f_con} --f_algn ${f_algn} --s_con ${s_con} --s_algn ${s_algn}`;
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
            my $superscaffold_metrics =  `perl ~/BNGCompare/N50.pl ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold.fasta $comparison_metrics_file`;
            print $superscaffold_metrics;
            my $collapse_agp = `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/collapse_agp.pl -a $agp_list_file`;
            print $collapse_agp;
            ###########################################################
            #                 Remove intermediate directories
            ###########################################################
            if (${previous_stitch} > 1)
            {
                my $highest_intermediate_stitch = ${previous_stitch} - 1;
                for my $former_stitch_num (1..${highest_intermediate_stitch})
                {
                    my $former_out_dir="${best_dir}/../${stringency}/stitch${former_stitch_num}/";
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

print "Done generating comparisons of BioNano and in silico genome maps\n";

##################################################################################
##############                  Documentation                   ##################
##################################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME

run_compare.pl - a script that compiles assembly metrics and runs stitch for the "best" assembly in all of the possible directories:'strict_t', 'default_t', 'relaxed_t', etc. These assemblies are created using Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/AssembleIrysXeonPhi.pl from https://github.com/i5K-KINBRE-script-share/Irys-scaffolding. The parameter `-b` is the directory with the "contigs" subdirectory created for the "best" assembly.
 
Copy script into assembly working directory and update other variables for project in "Project variables" section or run original script by adding the equivalent flags and values to your command. To do the former cd to the assembly working directory and "cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/run_compare.pl ." and then edit the new version to point to the best asssembly or the best assembly CMAP, etc.

=head1 USAGE

perl run_compare.pl [options]

Documentation options:

    -help    brief help message
    -man	    full documentation

Required options:

    -b	     best assembly directory
    -p	     project
    -e	     enzyme
    -f	     scaffold (reference) FASTA
    -r	     reference CMAP

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

=item B<-b, --best_dir>
 
Full path of the user selected directory of the "best" assembly without trailing slash (e.g. /home/bionano/bionano/Dros_psue_2014_012/default_t_100 ).
 
=item B<-p, --project>

The project name with no spaces, slashes or characters other than underscore (e.g. Trib_cast_0002).

=item B<-e, --enzyme>
 
A space separated list of the enzymes used to label the molecules and to in silico nick the sequence-based FASTA file. They can include BspQI BbvCI BsrDI bseCI (e.g. BspQI). If multiple enzymes were used enclose the list with quotes (e.g. "BspQI BbvCI").

=item B<-f, --fasta>

The FASTA that will be super-scaffolded based on alignment to the IrysView assembly. It is preferable to use the scaffold FASTA rather than the contigs. Many contigs will not be long enough to align.
 
=item B<-r, --r_cmap>

The reference CMAP produced from your sequence FASTA file.
 

=item B<--f_con, --fc>

The minimum confidence score for alignments for the first round of filtering. This should be the most stringent, highest, of the two scores.

=item B<--f_algn, --fa>

The minimum percent of the full potential length of the alignment allowed for the first round of filtering. This should be lower than the setting for the second round of filtering.

=item B<--s_con, --sc>

The minimum confidence score for alignments for the second round of filtering. This should be the less stringent, lowest, of the two scores.

=item B<--s_algn, --sa>

The minimum percent of the full potential length of the alignment allowed for the second round of filtering. This should be higher than the setting for the first round of filtering.

=item B<-n, --neg_gap>

Allows user to adjust minimum negative gap length allowed (default = 20000 bp).
 
=item B<-t, --p-value_T>

The RefAligner p-value threshold (default = 1e-8).


=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

The script outputs an XMAP with only molecules that scaffold contigs and an XMAP of all high quality alignments. Both XMAPs can be imported and viewed in the IrysView "comparisons" window if the original r.cmap and q.cmap are in the same folder when you import.

The script also lists summary metrics in a csv file.

In the same csv file, scaffolds that have alignments passing the user-defined length and confidence thresholds that align over less than 60% of the total length possible are listed. These may represent mis-assembled scaffolds.

In the same csv file, high quality but overlaping alignments in a csv file are listed. These may be candidates for further assembly using the overlaping contigs and paired end reads.

The script also creates a non-redundant (i.e. no scaffold is used twice) super-scaffold from a user-provided scaffold file and a filtered XMAP. If two scaffolds overlap on the superscaffold then a 100 "n" gap is used as a spacer between them. If adjacent scaffolds do not overlap on the super-scaffold than the distance between the begining and end of each scaffold reported in the XMAP is used as the gap length. If a scaffold has two high quality alignments the longest alignment is selected. If both alignments are equally long the alignment with the highest confidence is selected.

The script also outputs contigs, an agp, and a bed file of contigs within superscaffolds from the final super-scaffold fasta file.


B<QUICK START:>

git clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding

cd Irys-scaffolding/KSU_bioinfo_lab/stitch

mkdir results

perl stitch.pl -r sample_data/sample.r.cmap -x sample_data/sample.xmap -f sample_data/sample_scaffold.fasta -o results/test_output --f_con 15 --f_algn 30 --s_con 6 --s_algn 90

=cut
