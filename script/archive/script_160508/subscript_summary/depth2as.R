inputPath <- commandArgs()[5];
output1Path <- commandArgs()[6];
output2Path <- commandArgs()[7];

input <- read.table(file=inputPath, sep="\t", header=FALSE)
idx1 <- ( ( is.na(input$V6) ) | ( is.na(input$V7) ) )
depth <- input$V6[!idx1]
as <- input$V7[!idx1]

pdf(file=output1Path, height=640/72, width=640/72)
plot(depth, as, pch=20, xlim=c(1,4), ylim=c(0,1), xlab="Total CNs", ylab="Allele-specific CNs")
dev.off()

idx2 <- ( depth < 2 )
as[idx2] <- 1 + ( 1 - as[idx2] )

pdf(file=output2Path, height=640/72, width=640/72)
plot(depth, as, pch=20, xlim=c(1,4), ylim=c(0,2), xlab="Total CNs", ylab="Allele-specific CNs", yaxt="n")
par(new=T)
axis(2, at = c(0, 0.5, 1, 1.5, 2), labels = c(0, 0.5, 1, 0.5, 0), las = 0, lwd.ticks=1)
dev.off()
