#!/usr/bin/perl
##################################################################################
#
# USAGE: perl collapse_agp.pl [options]
# Script outputs a collapsed AGP file for AGP's generated from stitch iterations. The users inputs the full path for a text file using the "-a" flag. The contents of the text file are the full paths to the "_superscaffold.agp" files (one path per line). The paths should be listed in the order they were created (first stitch output, second stitch output, third stitch output... ).
#  Created by jennifer shelton 09/22/14
#
##################################################################################
use strict;
use warnings;
# use IO::File;
use File::Basename; # enable maipulating of the full path
# use File::Slurp;
# use List::Util qw(max);
# use List::Util qw(sum);
use Getopt::Long;
use Pod::Usage;
###############################################################################
##############         Print informative message             ##################
###############################################################################
print "###########################################################\n";
print "#  collapse_agp.pl Version 1.0                            #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 09/22/14                   #\n";
print "#  github.com/i5K-KINBRE-script-share                     #\n";
print "#  perl collapse_agp.pl -help # for usage/options         #\n";
print "#  perl collapse_agp.pl -man # for more details           #\n";
print "###########################################################\n";
###############################################################################
##############                get arguments                  ##################
###############################################################################
my $input_fasta;
my $agp_list;
my $man = 0;
my $help = 0;
GetOptions (
        'help|?' => \$help,
        'man' => \$man,
        'a|agp_list:s' => \$agp_list,

)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
my $dirname = dirname(__FILE__); # github directories (all github directories must be in the same directory)
###############################################################################
##############              run                              ##################
###############################################################################
my @agps;
open (AGP_LIST, "<", $agp_list) or die "Can't open $agp_list: $!";
while (<AGP_LIST>)
{
    unless (/^\s*$/)
    {
        chomp;
        push(@agps,$_);
    }
}

close (AGP_LIST);
@agps = reverse(@agps);
my $input_agp = $agps[0];
my ($basename, $directories, $suffix) = fileparse($input_agp,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
my $output_agp = "${directories}${basename}_temp_merged.agp";
open (my $output, ">", $output_agp) or die "Can't open $output_agp: $!";
print $output "##agp-version   2.0\n";
my $previous_object = "first";
my (%finished);
for my $index (0..$#agps)
{
    $input_agp = $agps[$index];
    open (my $input, "<", $input_agp) or die "Can't open $input_agp: $!";
    while (<$input>)
    {
        unless (/^#/)
        {
            chomp;
            my ($object,$object_beg,$object_end,$part_number,$component_type,$gap_length  ,$gap_type     ,$linkage      ,$Linkage_evidence,$component_id,$component_beg,$component_end,$orientation);
            $object = (split(/\t/))[0];
            $component_type = (split(/\t/))[4];
            unless ($finished{$object})
            {
                unless ($object eq "start")
                {
                    if ($previous_object ne $object)
                    {
                        $finished{$previous_object} = 1;
                    }
                }
                if ($component_type eq "W")
                {
                    ($object,$object_beg,$object_end,$part_number,$component_type,$component_id,$component_beg,$component_end,$orientation     ) = split(/\t/);
                    unless ($component_id =~ /Super_/)
                    {
                        print $output "$object\t$object_beg\t$object_end\t$part_number\t$component_type\t$component_id\t$component_beg\t$component_end\t$orientation\n";
                    }
                    else
                    {
                        my ($nests) = &get_nested_agp($object, $component_id, $index, $#agps, $orientation);
                        print $output "$nests";
                    }
                }
                else
                {
                    ($object,$object_beg,$object_end,$part_number,$component_type,$gap_length  ,$gap_type     ,$linkage      ,$Linkage_evidence) = split(/\t/);
                    print $output "$object\t$object_beg\t$object_end\t$part_number\t$component_type\t$gap_length\t$gap_type\t$linkage\t$Linkage_evidence\n";
                }
                $previous_object = $object; #reset previous
            }
        }
        if (eof)
        {
            $finished{$previous_object}=1;
        }
    }
    close($input);
}

sub get_nested_agp
{
    my ($sub_object, $sub_component_id, $sub_index, $sub_last_index,$sub_orientation) = @_ ;
    my $next_index = $sub_index + 1;
    my $nested_agp_lines;
    for my $i ($next_index..$sub_last_index)
    {
        my $sub_input_agp = $agps[$i];
        open (my $input, "<", $sub_input_agp) or die "Can't open $sub_input_agp: $!";
        while (<$input>)
        {
                    if (/^$sub_component_id\t/)
                    {
                        chomp;
                        my ($object,$object_beg,$object_end,$part_number,$component_type,$gap_length  ,$gap_type     ,$linkage      ,$Linkage_evidence,$component_id,$component_beg,$component_end,$orientation);
                        $object = (split(/\t/))[0];
                        $component_type = (split(/\t/))[4];
                        $orientation = (split(/\t/))[8];
                        
                        if ($sub_orientation eq '-')
                        {
                            if ($orientation eq '+'){ $orientation ='-';}
                            else{ $orientation ='+';}
                        }
                        if ($component_type eq "W")
                        {
                            my $new_orientation;
                            ($object,$object_beg,$object_end,$part_number,$component_type,$component_id,$component_beg,$component_end,$new_orientation     ) = split(/\t/);
                                $nested_agp_lines .= "$sub_object\t$object_beg\t$object_end\t$part_number\t$component_type\t$component_id\t$component_beg\t$component_end\t$orientation\n";
                        }
                        else
                        {
                            ($object,$object_beg,$object_end,$part_number,$component_type,$gap_length  ,$gap_type     ,$linkage      ,$Linkage_evidence) = split(/\t/);
                            $nested_agp_lines .= "$sub_object\t$object_beg\t$object_end\t$part_number\t$component_type\t$gap_length\t$gap_type\t$linkage\t$Linkage_evidence\n";
                        }

                    }
        }
        close($input);
    }
    if ($sub_orientation eq '-')
    {
        $nested_agp_lines = (join("\n",(reverse(split(/\n/,$nested_agp_lines)))));
        $nested_agp_lines .= "\n";
    }
    $finished{$sub_component_id} = 1;
    my @lines = split(/\n/,$nested_agp_lines);
    my ($object,$object_beg,$object_end,$part_number,$component_type,$component_id,$component_beg,$component_end,$orientation     );
    for (@lines)
    {
        chomp;
        $component_type = (split(/\t/))[4];
        $component_id = (split(/\t/))[5];
        if (($component_type eq "W")&&($component_id =~ /Super_/))
        {
            ($object,$object_beg,$object_end,$part_number,$component_type,$component_id,$component_beg,$component_end,$orientation     ) = split(/\t/);
            my ($within_nested) = &get_nested_agp($sub_object, $component_id, $sub_index, $sub_last_index,$orientation);
            $_ = $within_nested;
            $finished{$component_id} = 1 ;

        }
    }
    $nested_agp_lines = (join("\n",@lines));
    $nested_agp_lines .= "\n";
    return ($nested_agp_lines);
}
print "Done\n";
#    my ($object,$object_beg,$object_end,$part_number,$component_type,$component_id,$component_beg,$component_end,$orientation     );
#    my ($object,$object_beg,$object_end,$part_number,$component_type,$gap_length  ,$gap_type     ,$linkage      ,$Linkage_evidence);
close $output;
###############################################################################
##############            Repair AGP coordinates             ##################
###############################################################################
$input_agp = "${directories}${basename}_temp_merged.agp";
open (my $new_input, "<", $input_agp) or die "Can't open $input_agp: $!";
$output_agp = "${directories}${basename}_merged.agp";
open (my $new_output, ">", $output_agp) or die "Can't open $output_agp: $!";
print $new_output "##agp-version   2.0\n";
$previous_object = "first";
my $current_object_beg = 1;
my $current_part_number = 1;

while (<$new_input>)
{
    unless ((/^#/)||(/^\s*$/))
    {
        chomp;
        my ($object,$object_beg,$object_end,$part_number,$component_type,$gap_length  ,$gap_type     ,$linkage      ,$Linkage_evidence,$component_id,$component_beg,$component_end,$orientation);
        $object = (split(/\t/))[0];
        $component_type = (split(/\t/))[4];
        unless ($object eq "start")
        {
            if ($previous_object ne $object)
            {
                $current_object_beg = 1;
                $current_part_number = 1;
            }
        }
        if ($component_type eq "W")
        {
            ($object,$object_beg,$object_end,$part_number,$component_type,$component_id,$component_beg,$component_end,$orientation     ) = split(/\t/);
            $object_end = $current_object_beg + $component_end - 1;
            print $new_output "$object\t$current_object_beg\t$object_end\t$current_part_number\t$component_type\t$component_id\t$component_beg\t$component_end\t$orientation\n";
        }
        else
        {
            ($object,$object_beg,$object_end,$part_number,$component_type,$gap_length  ,$gap_type     ,$linkage      ,$Linkage_evidence) = split(/\t/);
            $object_end = $current_object_beg + $gap_length - 1;
            print $new_output "$object\t$current_object_beg\t$object_end\t$current_part_number\t$component_type\t$gap_length\t$gap_type\t$linkage\t$Linkage_evidence\n";
        }
        $previous_object = $object; #reset previous
        $current_object_beg = $object_end + 1;
        $current_part_number = $current_part_number + 1;
    }

}
close($new_input);

unlink $input_agp;

###############################################################################
##############                  Documentation                ##################
###############################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME

collapse_agp.pl - Script outputs a collapsed AGP file for AGP's generated from stitch iterations. The users inputs the full path for a text file using the "-a" flag. The contents of the text file are the full paths to the "_superscaffold.agp" files (one path per line). The paths should be listed in the order they were created (first stitch output, second stitch output, third stitch output... ).

=head1 USAGE
 
 perl collapse_agp.pl [options]
 
 Documentation options:
    -help    brief help message
    -man	    full documentation
 Required parameters:
    -a	    "_superscaffold.agp" agp list file

 
=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.
 
=item B<-a, --agp_list>
 
The fullpath for the agp list text file. The contents of the text file are the full paths to the "_superscaffold.agp" files (one path per line). The paths should be listed in the order they were created (first stitch output, second stitch output, third stitch output... ).


=back
 

=cut
