############################################
# Step 1: prep the Reference FASTA
############################################

## Grab genome FASTA and (then move to correct subdirectory after checking)
mkdir ~/fasta_and_cmap/project_id
cd ~/fasta_and_cmap/project_id
mkdir contigs/ scaffolds/ pseudomolecules/
touch README.md

## Download the genome FASTA
wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/example/example_genomic.fna.gz
gunzip example_genomic.fna.gz

## Determine if the FASTA is for contigs, scaffolds or pseudomolecules
# check:
grep ">" example_genomic.fna | head
grep ">" example_genomic.fna | tail
# Move to correct directory (make any notes in README.md)
mv example_genomic.fna pseudomolecules/example_genomic.fna

## Nick the genome and check label density (can add the --two_enzyme  flag to skip all but BspQI and BbvCI)
perl ~/Irys-scaffolding/KSU_bioinfo_lab/map_tools/nick_density.pl psuedomolecules/example_genomic.fna

## If single nicking is best move best CMAP next to the FASTA

mv psuedomolecules/cmaps/example_genomic_BspQI* suedomolecules/

## Else if dual nicking with BspQI and BbvCI is required run:
perl ~/bin/fa2cmap_multi.pl -v -i psuedomolecules/example_genomic.fna -e BspQI BbvCI

############################################
# Step 2: prep and run the assembly
############################################

## create directory in "~/bionano"
mkdir ~/bionano/project_id ; cd ~/bionano/project_id

## Move Datasets directory from IrysView to the assembly working directory and run prep_bnxXeonPhi (now with only the "assembly working directory" as an argument !!!!)

perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/prep_bnxXeonPhi.pl -a ~/bionano/project_id

## Next run AssembleIrysXeonPhi (with the "-a" flag and the "assembly working directory" replacing the "-b" flag and the bnx directory as an argument !!!!)

perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/AssembleIrysXeonPhi.pl -a ~/bionano/project_id -g 47 -p project_id -r ~/fasta_and_cmap/project_id/example_genomic_BspQI_BbvCI.cmap

## Assemble the molecule maps
nohup bash ~/bionano/project_id/assembly_commands.sh &> ~/bionano/project_id/assembly_commands_out.txt

## Run assembly_qcXeonPhi to select the best assembly
perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/assembly_qcXeonPhi.pl -a ~/bionano/project_id -g 47 -p project_id

###############################################################
# Step 3: Compare results to the reference and write the report
###############################################################

cd ~/bionano/project_id

cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/write_report.pl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/run_compare.pl .

## Next update other variables for project in "Project variables" section in both files and run .
perl ~/bionano/project_id/run_compare.pl

## Check "~/bionano/project_id/*_BNGCompare.csv" for best alignment parameters

## Comment "default_alignment" and uncomment "relaxed_alignment" in the "Default or Relaxed alignments" section of ~/bionano/project_id/write_report.pl
perl ~/bionano/project_id/write_report.pl

## Move text from "~/bionano/project_id/report.txt" and "~/bionano/project_id/*_BNGCompare_final.csv" into the report

## Move final files "~/bionano/project_id/project_id.tar.gz" to the Web Server


###############################################################
# Step 4: Email results
###############################################################

Hello,

I have included a pdf that describes assembly and alignment results for your data and an essential README file to get you started exploring your results. Your assembly output files and your raw data (.bnx) files are available at the FTP site listed below:

http://ftp.bioinformatics.ksu.edu/project_id
User: project_id
Password:


Please review the README.pdf file before installing or importing your files into IrysView.

We will hold your data for two months so please let us know if you have trouble downloading it in time.

Please let us know if you would also like your raw ".tiff" images. These files are much larger and slower to transfer and are not needed for further downstream analysis but we can copy them to a customer provided hard drive if you would prefer.

We are happy to go over our work with your group so please let us know.

Please also let me know if you have any questions,
