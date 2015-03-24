#!/usr/local/bin/Rscript
# USAGE: Rscript graph_assemblies <Assembly_parameter_tests.csv> <Assembly_parameter_tests.pdf> <ESTIMATED GENOME SIZE MB> <ASSEMBLY NAME>
# DESCRIPTION: Makes a histogram from BioNano genome map assembly metrics
args <- commandArgs(TRUE)

myblue <- rgb(0,0,1,3/4)

assemblymetrics <- read.csv(args[1], header=TRUE)

pdf(args[2], bg='white', width=20, height=10)

y1 <- (assemblymetrics$Breadth_of_alignment)

y2 <- (assemblymetrics$Total_alignment_length)

y3 <- (assemblymetrics$Cumulative_length)

x1 <- (assemblymetrics$Number)

number_assemblies <- length(assemblymetrics$Breadth_of_alignment)

min_lim <- min(assemblymetrics$Breadth_of_alignment) - 1

genome_size <- as.numeric(args[3])

max_lim <- genome_size + 1

possible_cumulative_max <- max(assemblymetrics$Cumulative_length)

possible_max <- possible_cumulative_max + 1

if (possible_cumulative_max>max_lim){
    max_lim <- possible_cumulative_max
}
#if (possible_cumulative_max>max_lim){
#max_lim <- possible_max
#}

#plot(x1, y1, ylim=c(min_lim,max_lim),main=args[4],xlab="Assembly name",ylab="Length (Mb)",pch=18,col=c(myblue),cex=3, axes=FALSE, ann=FALSE)
plot(x1, y1, ylim=c(min_lim,max_lim),main=args[4],xlab="Assembly name",ylab="Length (Mb)",pch=18,col=c(myblue),cex=3, xaxt="n")

NumberAssembblies <- length(assemblymetrics$Genome_map)

axis(1,tick = TRUE, labels = assemblymetrics$Genome_map, at = 1:number_assemblies )
axis(2,tick = TRUE, labels = TRUE)

abline(h=genome_size,col="grey",lty=2, lwd=3)

#points(x1,y1, pch=18,col=c(myblue),cex=3)
points(x1,y2, pch=25,col=c(myblue),cex=2,lwd=3)
points(x1,y3, pch=1,cex=2, lwd=4, col="yellow2",cex.lab=1)
legend( "right",legend=c("Cumulative length","Estimated genome size","Total aligned length","Breadth of alignment"),lty=c(NA,2,NA,NA),pch=c(1,NA,25,18), pt.cex=c(2,NA,2,3),col=c("yellow2","grey",myblue,myblue), lwd=3 )


dev.off()
