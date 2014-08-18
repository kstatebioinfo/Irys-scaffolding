#!/usr/bin/perl
##################################################################################
#   
#	USAGE: perl RefineAssembleIrys.pl [options]
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
use lib '/homes/bioinfo/bioinfo_software/perl_modules/lib/perl5/';
use File::Basename; # enable manipulating of the full path
use Getopt::Long;
use Pod::Usage;
use XML::Simple;
use Data::Dumper;
##################################################################################
##############         Print informative message                ##################
##################################################################################
print "###########################################################\n";
print "#  RefineAssembleIrys.pl                                  #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 2/3/14                     #\n";
print "#  github.com/i5K-KINBRE-script-share/Irys-scaffolding    #\n";
print "#  perl AssembleIrys.pl -help # for usage/options         #\n";
print "#  perl AssembleIrys.pl -man # for more details           #\n";
print "###########################################################\n";
#perl /Users/jennifershelton/Desktop/Perl_course_texts/scripts/Irys-scaffolding/KSU_bioinfo_lab/assemble/AssembleIrys.pl -g 230 -b test_bnx - p Oryz_sati_0027

##################################################################################
##############                get arguments                     ##################
##################################################################################
my ($bnx_dir,$ref,$project,$T,$current_assembly_dir);

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
#my $err="${bnx_dir}/all_flowcells/all_flowcells_adj_merged_bestref.err";
###################################################################################
###############              get parameters for XML              ##################
###################################################################################
#my ($FP,$FN,$SiteSD_Kb,$ScalingSD_Kb_square);
#open (ERR,'<',"$err") or die "can't open $err!\n";
#while (<ERR>) # get noise parameters
#{
#    if (eof)
#    {
#        my @values=split/\t/;
#        for my $value (@values)
#        {
#            s/\s+//g;
#        }
#        my $map_ratio = $values[9]/$values[7];
#        ($FP,$FN,$SiteSD_Kb,$ScalingSD_Kb_square)=($values[1],$values[2],$values[3],$values[4]);
#    }
#}
##################################################################################
##############                 parse XML                        ##################
##################################################################################

my %min_length = (
    'relaxed_ml' => 100,
    'strict_ml' => 180
);
open (OUT_ASSEMBLE, '>>',"${bnx_dir}/assembly_commands.sh"); # for assembly commands
print OUT_ASSEMBLE "##################################################################\n";
print OUT_ASSEMBLE "##### CORRESPONDING FIRST ASSEMBLY WAS: ${project}_${current_assembly_dir} \n";
print OUT_ASSEMBLE "##### BEFORE RUNNING SECOND ROUND OF ASSEMBLIES, COMMENT THE SECTION MATCHING\n"; 
print OUT_ASSEMBLE "##### ALL FIRST ASSEMBLY COMMANDS AND UNCOMMENT THE SECTION MATCHING THE SECOND\n"; 
print OUT_ASSEMBLE "##### ASSEMBLY COMMANDS FOR THE BEST, FIRST ASSEMBLY \n";
print OUT_ASSEMBLE "##################################################################\n";
for my $stringency (keys %min_length)
{

    ##################################################################
    ##############     Create assembly directories  ##################
    ##################################################################
    my $out_dir = "${current_assembly_dir}/${stringency}";
    unless(mkdir $out_dir)
    {
    		print "Error: $out_dir already exists exiting\n";
		die "Unable to create $out_dir\n";
	}
    ##################################################################
    ##############        Set assembly parameters   ##################
    ##################################################################
    my $xml_infile = "${dirname}/OptArguments2.xml";
    my $xml_outfile = "${current_assembly_dir}/${stringency}/${stringency}_optArguments.xml";
    my $xml = XMLin($xml_infile);
    open (OUT, '>',"${current_assembly_dir}/${stringency}/dumped.txt");
    print OUT Dumper($xml);
    ########################################
    ##             BNX filter             ##
    ########################################
    $xml->{bnx_sort}->{flag}->[0]->{val0} = $min_length{$stringency}; # min length

    #########################################
    ##         Write out XML               ##
    #########################################

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
    print OUT_ASSEMBLE "##################################################################\n";
    print OUT_ASSEMBLE "##### NEW ASSEMBLY STRINGENCY: ${stringency} \n";
    print OUT_ASSEMBLE "##################################################################\n";
    print OUT_ASSEMBLE "# python2 /homes/bioinfo/bioinfo_software/bionano/scripts/pipelineCL.py -y -T 32 -j 8 -N 2 -i 5 -a $xml_final -w -t /homes/bioinfo/bioinfo_software/bionano/tools/ -l $out_dir -b ${bnx_dir}/all_flowcells/all_flowcells_adj_merged.bnx -V 1 -e ${project}_${stringency} -p 0 -r $ref -U -C ${dirname}/clusterArguments.xml\n"; # testing -V 1 for variant calling
}
print "done\n";

##################################################################################
##############                  Documentation                   ##################
##################################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME
 
 RefineAssembleIrys.pl - a package of scripts that creates optArgument.xml files and commands to run a strict and relaxed assembly by altering the minimum length filter on the Beocat SGE cluster.
 
=head1 USAGE
 
 perl RefineAssembleIrys.pl [options]
 
 Documentation options:
 -help    brief help message
 -man	    full documentation
 Required options:
 -b	     directory with all BNX's that were assembled 
 -a	     current best assembly directory
 -r	     reference CMAP
 -p	     project name for all assemblies
 -t	     p-value threshold chosen from the first assemblies
 
 
=head1 OPTIONS
 
=over 8
 
=item B<-help>
 
 Print a brief help message and exits.
 
=item B<-man>
 
 Prints the more detailed manual page with output details and exits.
 
=item B<-b, --bnx_dir>
 
 The directory with all BNX's that were assembled. Use absolute not relative paths. Do not use a trailing / for this directory.
 
=item B<-a, --current_assembly_dir>
 
 The directory with the current best assembly that was assembled (e.g. '/home/data/strict_t'). Use absolute not relative paths. Do not use a trailing / for this directory. 
 
=item B<-t, --threshold>
 
 The best p-value threshold (chosen from the first assemblies).
 
=item B<-r, --ref>
 
 The full path to the reference genome CMAP.
 
=item B<-p, --project>
 
 The project id. This will be used to name all assemblies
 
=back
 
=head1 DESCRIPTION
 
B<OUTPUT DETAILS:>
 
 strict - This directory holds the output for the strictest assembly (where the minimum length was set to 180).
 
 relaxed - This directory holds the output for the laxest assembly (where the minimum length was set to 100).
 
 second_assembly_commands.sh - These are the commands to start the first pass of assemblies. In these strict and relaxed minimum lengths will be used.
 
 
B<Test with sample datasets:>
 
 git clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding
 
 # no test dataset is available yet but here is an example of a command
 
 perl Irys-scaffolding/KSU_bioinfo_lab/assemble/RefineAssembleIrys.pl -a  -b  -r  -p -t Test_project_name > testing_log.txt
 
 bash second_assembly_commands.sh
 
=cut






