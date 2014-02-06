#!/bin/perl
##################################################################################
#   
#	USAGE: perl script.pl [options]
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
use File::Basename; # enable maipulating of the full path
use Getopt::Long;
use Pod::Usage;
use XML::Simple;
use Data::Dumper;
##################################################################################
##############         Print informative message                ##################
##################################################################################
print "###########################################################\n";
print "#  RefineAssembleIrys.pl                                        #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 2/3/14                    #\n";
print "#  github.com/                                            #\n";
print "#  perl AssembleIrys.pl -help # for usage/options         #\n";
print "#  perl AssembleIrys.pl -man # for more details           #\n";
print "###########################################################\n";
#perl /Users/jennifershelton/Desktop/Perl_course_texts/scripts/Irys-scaffolding/KSU_bioinfo_lab/assemble/AssembleIrys.pl -g 230 -b test_bnx - p Oryz_sati_0027

##################################################################################
##############                get arguments                     ##################
##################################################################################
my ($bnx_dir,$genome,$reference,$project);

my $man = 0;
my $help = 0;
GetOptions (
			  'help|?' => \$help, 
			  'man' => \$man,
			  'a|current_assembly_dir:s' => \$current_assembly_dir,
			  'b|bnx_dir:s' => \$bnx_dir,
              'r|ref:s' => \$ref,
              'p|proj:s' => \$project,
              't|threshold:s' => \$T,
              )  
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
my $dirname = dirname(__FILE__);
my $err="${bnx_dir}/all_flowcells/all_flowcells_adj_merged_bestref.err";
##################################################################################
##############              get parameters for XML              ##################
##################################################################################
my ($FP,$FN,$SiteSD_Kb,$ScalingSD_Kb_square);
open (ERR,'<',"$err") or die "can't open $err!\n";
while (<ERR>) # get noise parameters
{
    if (eof)
    {
        my @values=split/\t/;
        for my $value (@values)
        {
            s/\s+//g;
        }
        my $map_ratio = $values[9]/$values[7];
        ($FP,$FN,$SiteSD_Kb,$ScalingSD_Kb_square)=($values[1],$values[2],$values[3],$values[4]);
    }
}
##################################################################################
##############                 parse XML                        ##################
##################################################################################

my %min_length = (
'strict' => 180,
'relaxed' => 100
);
open (OUT_ASSEMBLE, '>',"${bnx_dir}/second_assembly_commands.sh"); # for assembly commands
for my $stringency (keys %min_length)
{
    ##################################################################
    ##############     Create assembly directories  ##################
    ##################################################################
    my $out_dir = "${current_assembly_dir}/${stringency}";
    unless(mkdir $out_dir)
    {
		die "Unable to create $out_dir\n";
	}
    ##################################################################
    ##############        Set assembly parameters   ##################
    ##################################################################
    my $xml_infile = "${dirname}/optArguments.xml";
    my $xml_outfile = "${current_assembly_dir}/${stringency}/${stringency}_optArguments.xml";
    my $xml = XMLin($xml_infile);
    open (OUT, '>',"${current_assembly_dir}/${stringency}/dumped.txt");
    print OUT Dumper($xml);
    ########################################
    ##             Pairwise               ##
    ########################################
    $xml->{pairwise}->{flag}->[0]->{val0} = $T;
    ########################################
    ##               Noise                ##
    ########################################
    $xml->{noise0}->{flag}->[0]->{val0} = $FP;
    $xml->{noise0}->{flag}->[1]->{val0} = $FN;
    $xml->{noise0}->{flag}->[2]->{val0} = $ScalingSD_Kb_square;
    $xml->{noise0}->{flag}->[3]->{val0} = $SiteSD_Kb;
    ########################################
    ##            Assembly                ##
    ########################################
    $xml->{assembly}->{flag}->[0]->{val0} = $T;
    ########################################
    ##              RefineA               ##
    ########################################
    $xml->{refineA}->{flag}->[2]->{val0} = $T;
    ########################################
    ##              RefineB               ##
    ########################################
    $xml->{refineB}->{flag}->[2]->{val0} = $T/10;
    $xml->{refineB}->{flag}->[9]->{val0} = 25; #min split length
    ########################################
    ##              RefineFinal           ##
    ########################################
    $xml->{refineFinal}->{flag}->[2]->{val0} = $T/10;
    $xml->{refineFinal}->{flag}->[16]->{val0} = 1e-5; # endoutlier/outlier
    $xml->{refineFinal}->{flag}->[17]->{val0} = 1e-5; # endoutlier/outlier
    ########################################
    ##              Extension             ##
    ########################################
    $xml->{extension}->{flag}->[3]->{val0} = $T/10;
    $xml->{extension}->{flag}->[20]->{val0} = 1e-5; # endoutlier/outlier
    $xml->{extension}->{flag}->[20]->{val0} = 1e-5; # endoutlier/outlier
    ########################################
    ##               Merge                ##
    ########################################
    $xml->{merge}->{flag}->[0]->{val0} = 75; # pairmerge
    $xml->{merge}->{flag}->[1]->{val0} = $T/1000;
    XMLout($xml,OutputFile => $xml_outfile,);
    #########################################
    ## Correct the document head and tail  ##
    #########################################
    my $xml_final = "${current_assembly_dir}/${stringency}/${stringency}_final_optArguments.xml";
    open (OPTARGFINAL, '>', $xml_final) or die "can't open $xml_final\n";
    open (OPTARG, '<', $xml_outfile) or die "can't open $xml_outfile\n";
    while (<OPTARG>)
    {
        if (/<opt>/)
        {
            print OPTARGFINAL '<?xml version="1.0"?>';
            
            print OPTARGFINAL "\n\n<moduleArgs>\n";
        }
        elsif (/<\/opt>/)
        {
            print OPTARGFINAL "\n</moduleArgs>\n";
        }
        else
        {
            print OPTARGFINAL;
        }
        
    }
    `rm $xml_outfile`; # remove the intermediate xml file
    ##################################################################
    ##############        Write assembly command    ##################
    ##################################################################
    print OUT_ASSEMBLE "#!/bin/bash\n";
    print OUT_ASSEMBLE "python ~/scripts/pipelineCL.py -T 64 -j 16 -N 4 -i 5 -a $xml_final -w -t /home/irys/tools -l $out_dir -b ${bnx_dir}/all_flowcells/all_flowcells_adj_merged.bnx -e $project -p 0 -r $ref\n"; # removed -V parameter because an error was reported
}

##################################################################################
##############          Create new assembly parameters          ##################
##################################################################################


##################################################################################
##############                  Documentation                   ##################
##################################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME
 
 script.pl - a package of scripts that ...
 
 =head1 USAGE
 
 perl script.pl [options]
 
 Documentation options:
 -help    brief help message
 -man	    full documentation
 Required options:
 -b	     directory with all BNX's meant for assembly (any BNX in this directory will be used in assembly)
 -g	     genome size in Mb
 -r	     reference CMAP
 -p	     project name for all assemblies
 
 
 =head1 OPTIONS
 
 =over 8
 
 =item B<-help>
 
 Print a brief help message and exits.
 
 =item B<-man>
 
 Prints the more detailed manual page with output details and exits.
 'help|?' => \$help,
 'man' => \$man,
 'b|bnx_dir:s' => \$bnx_dir,
 'g|genome:i' => \$genome,
 'r|ref:s' => \$reference,
 'p|proj:s' => \$project
 
 =item B<-b, --bnx_dir>
 
 The directory with all BNX's meant for assembly (any BNX in this directory will be used in assembly. Do not use a trailing / for this directory.
 
 =item B<-g, --genome>
 
 The estimated size of the genome in Mb.
 
 =item B<-r, --ref>
 
 The full path to the reference genome CMAP.
 
 =item B<-p, --project>
 
 The project id. This will be used to name all assemblies
 
 =back
 
 =head1 DESCRIPTION
 
 B<OUTPUT DETAILS:>
 
 strict_t - This directory holds the output for the strictest assembly (where the p-value threshold is divided by 10).
 
 relaxed_t - This directory holds the output for the laxest assembly (where the p-value threshold is multiplied by 10).
 
 default_t - This directory holds the output for the default assembly (where the p-value threshold is used as-is).
 
 bestref_effect_summary.csv - this shows the difference between running a molecule quality report with and without - BestRef. If the values change substantially than your p-value threshold may be too lax.
 
 assembly_commands.txt - These are the commands to start the first pass of assemblies. In these strict, relaxed, and default p-value thresholds will be used.
 
 flowcell_summary.csv - This file can be evaluated to check quality (ability to align to reference for each flowcell.
 
 B<Test with sample datasets:>
 
 git clone https://github.com/i5K-KINBRE-script-share
 
 # no test dataset is available yet but here is an example of a command
 
 perl Irys-scaffolding/KSU_bioinfo_lab/assemble/AssembleIrys.pl -g  -b  -r  -p Test_project_name > testing_log.txt
 
 =cut





