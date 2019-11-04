library("ggpubr")
library("ggplot2")
idata <- as.matrix(read.csv("/Users/Mingyu/Desktop/0725cL-50um-e10.W-11.selected.norm.tsv",sep="\t"))
tsne <- Rtsne::Rtsne(idata, perplexity = 30, pca=F)
head(tsne$Y)
pdf("/Users/Mingyu/Desktop/tsne.pdf",height=4,width=5)
dat.plot <- data.frame(pos=rownames(idata),
                       cluster=factor(apply(idata,1,which.max)),
                       tsne.1=tsne$Y[,1],
                       tsne.2=tsne$Y[,2],
                       stringsAsFactors = F)

ggplot(dat.plot,aes(tsne.1,tsne.2)) +
  geom_point(aes(color=cluster),size = 1) +
  scale_color_manual(values = c("1"=5,"2"=8,"3"=4,"4"=7,"5"=10,"6"="violet",
                                "7"=3,"8"=9,"9"="#9A32CD","10"="#009ACD","11"="chocolate")) +
  theme_bw()
dev.off()
