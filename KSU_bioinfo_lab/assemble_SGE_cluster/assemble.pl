#!/usr/bin/perl
##################################################################################
#   
#	USAGE: perl assemble.pl [bnx_dir] [reference] [p_value Threshold] [script directory] [project prefix]
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
use lib '/homes/bioinfo/bioinfo_software/perl_modules/lib/perl5/';
use XML::Simple;
use Data::Dumper;
##################################################################################
##############                     get arguments                ##################
##################################################################################
my $bnx_dir = $ARGV[0];
my $ref = $ARGV[1];
my $T = $ARGV[2];
my $dirname = $ARGV[3];
my $project = $ARGV[4];
print "bnx_dir = $ARGV[0]\n";
print "ref = $ARGV[1]\n";
print "T = $ARGV[2]\n";
print "dirname = $ARGV[3]\n";
my $err="${bnx_dir}/all_flowcells/all_flowcells_adj_merged_bestref.err";
##################################################################################
##############              get parameters for XML              ##################
##################################################################################
my $T_relaxed = $T * 10;
my $T_strict = $T/10;
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

my %p_value = (
    'default_t' => "$T",
    'relaxed_t' => "$T_relaxed",
    'strict_t' => "$T_strict",
);
open (OUT_ASSEMBLE, '>',"${bnx_dir}/assembly_commands.sh"); # for assembly commands
##################################################################
##############        Write bash scripts        ##################
##################################################################

print OUT_ASSEMBLE "#!/bin/bash\n";
print OUT_ASSEMBLE ". /usr/bin/virtualenvwrapper.sh\n";
print OUT_ASSEMBLE "workon bionano\n";
print OUT_ASSEMBLE "export DRMAA_LIBRARY_PATH=/opt/sge/lib/lx3-amd64/libdrmaa.so.1.0\n";
print OUT_ASSEMBLE "##################################################################\n";
print OUT_ASSEMBLE "#####             FIRST ASSEMBLY COMMANDS                    #####\n";
print OUT_ASSEMBLE "##################################################################\n";
for my $stringency (keys %p_value)
{
    ##################################################################
    ##############     Create assembly directories  ##################
    ##################################################################
    my $out_dir = "${bnx_dir}/${stringency}";
    unless(mkdir $out_dir)
    {
		die "Exiting because unable to create $out_dir\n";
	}
    ##################################################################
    ##############        Set assembly parameters   ##################
    ##################################################################
    my $xml_infile = "${dirname}/OptArguments2.xml";
    my $xml_outfile = "${bnx_dir}/${stringency}/${stringency}_optArguments.xml";
    my $xml = XMLin($xml_infile);
    open (OUT, '>',"${bnx_dir}/${stringency}/dumped.txt");
    print OUT Dumper($xml);
    ########################################
    ##             BNX filter             ##
    ########################################
    $xml->{bnx_sort}->{flag}->[0]->{val0} = 150; # minlen
    ########################################
    ##        initialAssembly             ##
    ########################################
    $xml->{initialAssembly}->{flag}->{val0} = $p_value{$stringency};
    ########################################
    ##          extendRefine              ##
    ########################################
    $xml->{extendRefine}->{flag}->{val0} = $p_value{$stringency}/10;
    ########################################
    ##               merge                ##
    ########################################
    $xml->{merge}->{flag}->[1]->{val0} = $p_value{$stringency}/10000;
    #########################################
    ##         Write out XML               ##
    #########################################
    XMLout($xml,OutputFile => $xml_outfile,);
    #########################################
    ## Correct the document head and tail  ##
    #########################################
    my $xml_final = "${bnx_dir}/${stringency}/${stringency}_final_optArguments.xml";
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
    print OUT_ASSEMBLE "#####           FIRST ASSEMBLY: ${stringency}                \n";
    print OUT_ASSEMBLE "##################################################################\n";
    print OUT_ASSEMBLE "python2 /homes/bioinfo/bioinfo_software/bionano/scripts/pipelineCL.py -y -T 32 -j 8 -N 2 -i 5 -a $xml_final -w -t /homes/bioinfo/bioinfo_software/bionano/tools/ -l $out_dir -b ${bnx_dir}/all_flowcells/all_flowcells_adj_merged.bnx -V 1 -e ${project}_${stringency} -p 0 -r $ref -U -C ${dirname}/clusterArguments.xml\n";
    ##################################################################
    ##############  Write second round of assembly commands ##########
    ##################################################################
    {
        my $second_commands= `perl ${dirname}/RefineAssembleIrys.pl -a ${out_dir} -b ${bnx_dir} -r $ref -p ${project}_${stringency} -t $p_value{$stringency}`;
        print "$second_commands";
    }
}
#########################################
##       Clean some excess files       ##
#########################################
`rm ${bnx_dir}/all_flowcells/all_flowcells_adj_merged_r.cmap`;
`rm ${bnx_dir}/all_flowcells/all_flowcells_adj_merged_q.cmap`;
`rm ${bnx_dir}/all_flowcells/all_flowcells_adj_merged.map`;
`rm ${bnx_dir}/all_flowcells/all_flowcells_adj_merged.xmap`;

print "done\n";

