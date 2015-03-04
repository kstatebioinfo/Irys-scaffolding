#!/usr/bin/Rscript
# USAGE: Rscript plot_bnx_rescaling_factors.R <input tab delimited file> < output PDF file> <total number of scans>
# DESCRIPTION: Make a plot of bnx rescaling factors for each scan for all flowcells

args <- commandArgs(TRUE)

myblue <- rgb(0,0,1,3/4)

rescaling_factor_table <- read.table(args[1], header=TRUE)

pdf(args[2], bg='white', width=15, height=5)

rescaling_factor <- c(rescaling_factor_table$scale)

plot (rescaling_factor, xaxt = "n", las = 2, ylim=c(0.95,1.05), xlab="Scan", ylab="Rescaling factor",main="Single molecule map rescaling factor by scan for all flowcells")

lines(rescaling_factor, col=c(myblue))
axis(1, at=1:args[3], labels=(rescaling_factor_table$scan))

dev.off()