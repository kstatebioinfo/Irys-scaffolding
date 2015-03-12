#!/usr/local/bin/Rscript
# USAGE: Rscript graph_assemblies <Assembly_parameter_tests.csv> <Assembly_parameter_tests.pdf> <ESTIMATED GENOME SIZE MB>
# DESCRIPTION: Makes a histogram from BioNano genome map assembly metrics
args <- commandArgs(TRUE)

myblue <- rgb(0,0,1,3/4)

assemblymetrics <- read.csv(args[1], header=TRUE)

pdf(args[2], bg='white', width=15, height=10)

y1 <- (assemblymetrics$Breadth_of_alignment)

y2 <- (assemblymetrics$Total_alignment_length)

y3 <- (assemblymetrics$Cumulative_length)

x1 <- factor(assemblymetrics$Genome_map)


min_lim <- min(assemblymetrics$Breadth_of_alignment) - 1

genome_size <- as.numeric(args[3])

max_lim <- genome_size + 1

possible_cumulative_max <- max(assemblymetrics$Cumulative_length)

possible_max <- possible_cumulative_max + 1

if (possible_max>max_lim){
    max_lim <- possible_max
}

plot(x1, ylim=c(min_lim,max_lim),main="Assembly metrics for selection of best assembly",xlab="Assembly name",ylab="Length (Mb)",col="white",border="white")

axis(1,tick = TRUE, labels = FALSE)

abline(h=genome_size,col="grey",lty=2, lwd=3)

points(x1,y1, pch=18,col=c(myblue),cex=3)
points(x1,y2, pch=25,col=c(myblue),cex=2,lwd=3)
points(x1,y3, pch=1,cex=2, lwd=4, col="yellow2",cex.lab=1)
legend( "right",legend=c("Cumulative length","Estimated genome size","Total aligned length","Breadth of alignment"),lty=c(NA,2,NA,NA),pch=c(1,NA,25,18), pt.cex=c(2,NA,2,3),col=c("yellow2","grey",myblue,myblue), lwd=3 )


dev.off()
