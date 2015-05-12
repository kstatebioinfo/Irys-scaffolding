#!/usr/local/bin/Rscript
# USAGE: Rscript histograms.R <lengths_file> <mol_intensities_file> <mol_snrs_file> <min_length> <mol_NumberofLabels_file> <mean_label_snr_file> <mean_label_intensity_file>
# DESCRIPTION: Plots QC graphs for bnx_stats.pl
args <- commandArgs(TRUE)


## Molecule map lengths (Mb) ##

lengths <- read.table(args[1], header=FALSE)
names(lengths) <- c("Lengths")
p1 <- hist(lengths$Lengths,breaks=100)

## Molecule map average intensities ##
mol_intensities <- read.table(args[2], header=FALSE)
names(mol_intensities) <- c("Mol_intensities")
p2 <- hist(mol_intensities$Mol_intensities,breaks=100)

## Molecule map average SNRs ##
mol_snrs <- read.table(args[3], header=FALSE)
names(mol_snrs) <- c("Mol_SNRs")
p3 <- hist(mol_snrs$Mol_SNRs,breaks=100)

## Molecule map average NumberofLabels ##
mol_NumberofLabels <- read.table(args[4], header=FALSE)
names(mol_NumberofLabels) <- c("Mol_NumberofLabels")
p4 <- hist(mol_NumberofLabels$Mol_NumberofLabels,breaks=100)

## Per molecule map average Label SNR ##
mean_label_snr <- read.table(args[5], header=FALSE)
names(mean_label_snr) <- c("Label_MeanSNR")
p5 <- hist(mean_label_snr$Label_MeanSNR,breaks=100)

## Per molecule map average Label intensity ##
mean_label_intensity <- read.table(args[6], header=FALSE)
names(mean_label_intensity) <- c("Label_MeanIntensity")
p6 <- hist(mean_label_intensity$Label_MeanIntensity,breaks=100)

myblue <- rgb(0,0,1,3/4)
#myorange <- rgb(1,0,0,3/4)
pdf("MapStatsHistograms.pdf", bg='white', width=15, height=5)
a = args[7]
b = args[8]
c = args[9]
d = args[10]

#pdf('out.pdf',width=5,height=5)
plot(NA, xlim=c(0,5), ylim=c(0,5), bty='n',
xaxt='n', yaxt='n', xlab='', ylab='')
text(1,4,a, pos=4,col=c(myblue), font=2, cex=2)
text(1,3,b, pos=4, cex=1.5)
text(1,2,c, pos=4, cex=1.5)
text(1,1,d, pos=4, cex=1.5)
#points(rep(1,4),1:4, pch=15)

plot( p1, col=c(myblue),main="Molecule Map Length",xlab="Per molecule map length (kb)",ylab="Count", xaxt="n")  # first histogram
at <- seq(from = 0, to = max(lengths$Lengths), by = 100)
axis(side = 1, at = at)
plot( p2, col=c(myblue),main="Average Molecule Map Intensity",xlab="Per molecule map average backbone intensity",ylab="Count", xaxt="n")  # first histogram
at <- seq(from = 0, to = max(mol_intensities$Mol_intensities), by = 0.1)
axis(side = 1, at = at)
plot( p3, col=c(myblue),main="Average Molecule Map SNR",xlab="Per molecule map average backbone SNR (SNRs above 50 not shown)",ylab="Count", xaxt="n")  # first histogram
at <- seq(from = 0, max(mol_snrs$Mol_SNRs), by = 1)
axis(side = 1, at = at)
plot( p4, col=c(myblue),main="Number of Labels",xlab="Per molecule map number of labels (molecules with 200 or more labels not shown)",ylab="Count", xaxt="n")  # first histogram
at <- seq(from = 0, to = max(mol_NumberofLabels$Mol_NumberofLabels), by = 10)
axis(side = 1, at = at)
plot( p5, col=c(myblue),main="Average Label SNR",xlab="Per molecule map average label SNR", ylab="Count", xaxt="n")  # first histogram
at <- seq(from = 0, to = max(mean_label_snr$Label_MeanSNR), by = 2)
axis(side = 1, at = at)
plot( p6, col=c(myblue),main="Average Label Intensity",xlab="Per molecule map average label intensity",ylab="Count", xaxt="n")  # first histogram
at <- seq(from = 0, to = max(mean_label_intensity$Label_MeanIntensity), by = 0.02)
axis(side = 1, at = at)


dev.off()


