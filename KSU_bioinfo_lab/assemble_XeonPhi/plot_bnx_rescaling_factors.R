#!/usr/bin/Rscript
# USAGE: Rscript plot_bnx_rescaling_factors.R <input tab delimited file> < output PDF file> <total number of scans> <positions of first scans>
# DESCRIPTION: Make a plot of bnx rescaling factors for each scan for all flowcells

args <- commandArgs(TRUE)

argscounts <- length(args)


myblue <- rgb(0,0,1,3/4)

rescaling_factor_table <- read.table(args[1], header=TRUE)

pdf(args[2], bg='white', width=15, height=5)

rescaling_factor_max <- max(rescaling_factor_table$scale)
rescaling_factor_min <- min(rescaling_factor_table$scale)
rescaling_factor <- c(rescaling_factor_table$scale)

plot (rescaling_factor, xaxt = "n", las = 2, ylim=c(rescaling_factor_min,rescaling_factor_max), xlab="Scan number", ylab="Rescaling factor",main="Single molecule map rescaling factor by scan for all flowcells")

lines(rescaling_factor, col=myblue)
axis(1, at=1:args[3], labels=(rescaling_factor_table$scan))


#abline(v=c(args[4]), untf = FALSE)

for (t in 1:argscounts) {
    if (t>3){
        abline(v=c(args[t]), untf = FALSE, lty=2,col=myblue)
    }
}

legend( "topright",legend="First scan of a BNX file",lty=2, col=myblue )

dev.off()