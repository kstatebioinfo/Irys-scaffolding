#!/usr/bin/Rscript
# USAGE: Rscript plot_bpp.R <input tab delimited file> < output PDF file>
# Description: Make plot of bpp per scan for a list of flowcells

args=(commandArgs(TRUE))

pdf("/homes/bioinfo/bionano/Corv_coro_2014_051/bnx/bpp_graph.pdf", bg='white', width=15, height=5)
bpp_table <- read.table("/homes/bioinfo/bionano/Corv_coro_2014_051/bnx/bpp_list.txt_sorted.tab", header=TRUE)

pdf("args[2]", bg='white', width=15, height=5)

bpp_table <- read.table("args[1]", header=TRUE)

bpp <- c(bpp_table$bpp)


#names(bpp) <- c(bpp_table$scan)


plot (bpp, las = 2, ylim=c(400,600), type="n")

lines(bpp, col="red")

#axis(1, at=1, lab=c(bpp_table$scan))

dev.off()