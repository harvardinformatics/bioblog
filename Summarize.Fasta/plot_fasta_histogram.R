#Make histrogram plot from the output files of fasta_stats.pl
#
#Author:
# Chris Williams
# Harvard Informatics And Scientific Applications
# http://informatics.fas.harvard.edu

argv <- commandArgs(TRUE)
histfile  <- argv[1]
statsfile <- argv[2]
oname     <- argv[3]
outputdir <- argv[4]

fhist = read.table(histfile, header=F, sep="\t", row.names=1)
num.shown=nrow(fhist)
#num.shown=30
histpdf = paste(outputdir, "/", oname, ".hist.pdf" ,sep="")
pdf(histpdf, width=7, height=7)
barplot(height=fhist[1:num.shown,1],
  main=paste("Transcript Length Distribution\n",oname,sep=""),
  cex.names=.7,
  col = c("Brown"),
  las=3,
  names.arg=row.names(fhist)[1:num.shown]
)

labdf = read.table(statsfile,sep = "",row.names=1)
labstr = ""
for (i in 1:nrow(labdf)) {
    labstr = paste(labstr, row.names(labdf)[i], ": ", labdf[i,1], "\n", sep="");
}
labstr = gsub("_", " ", labstr)
text(nrow(fhist)*5/8, max(fhist)*2/3, labels=labstr, adj = 0)
dev.off()

