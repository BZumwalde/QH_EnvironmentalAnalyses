##################
#Get climate variables 
##################
library(stats); library(dismo); library(maptools); library(rgdal)

setwd("C:/Users/shoban/Downloads/wc2.0_2.5m_bio")
 files <- list.files(pattern='tif', full.names=TRUE) #Load climate files
 bioclim2.5 <- stack(files) #Create a raster stack

setwd("C:/Users/shoban/Documents/GitHub/QH_EnvironmentalAnalyses/Hoban_work/")
 QHloc <- read.csv("Hob_QHOccur_gen.csv", sep=",", header=T, stringsAsFactors = FALSE) #Loading locations

clim <- extract(bioclim2.5, QHloc[,1:2]) 
#subtract the correlated variables
clim<-clim[,-c(1,5,6,13,14,16,18)]

#add in lat/long- optional... I would argue that lat long are not biologically relevant here
#clim_and_loc<-cbind(clim, QHloc[,1:2])


#################
#Get genetic data
##################
setwd("C:/Users/shoban/Dropbox/Projects/IN_PROGRESS/Oak_popgen_analyses/Qhavardii/7indiv_11loci/")
gen_sum_stats<-read.csv("Qha_summ_stats.csv") 
#these are the genetic statistics: number clones (5). heterozygosity (6), allelic richness (8), pw FST (9), relatedness (10)
stat_list<-c(5,6,8,9,10)


##################
#Regressions
################

pop_set<-list(1:13,14:26,1:26)
point_colors<-c(rep("red",13),rep("blue",13))
point_shapes<-c(rep(21,13),rep(24,13))

for (p in 1:3){
if (p==1) region<-"E"; if (p==2) region<-"W"; if (p==3) region<-"overall"
	#place to keep regression results (p values) of all regressions run
	reg_pval<-matrix(nrow=dim(clim)[2],ncol=5)
	reg_r2<-matrix(nrow=dim(clim)[2],ncol=5)

	for (ss in 1:length(stat_list)){
		for (c in 1:dim(clim)[2]){
			reg_pval[c,ss]<-summary(lm(gen_sum_stats[pop_set[[p]],stat_list[ss]]~clim[pop_set[[p]],c]))[4][[1]][8]
			reg_r2[c,ss]<-unlist(summary(lm(gen_sum_stats[pop_set[[p]],stat_list[ss]]~clim[pop_set[[p]],c]))[8]	)
		}
	}
	 #identify rows and columns with significant p values 
	 row_col_signif<-which( matrix(p.adjust(reg_pval,"BH"),nrow=12,ncol=5)<0.05,arr.ind=T)
	 
	 sort(reg_r2)
	 
	setwd("C:/Users/shoban/Documents/GitHub/QH_EnvironmentalAnalyses/Hoban_work/")
	 #read in the names of the bioclim variables for the axis names of the plots
	 #the x is for those variables to be removed due to correlation
	 list_bioc<-read.csv("list_bioclim_var.csv")
	 list_bioc<-list_bioc[-which(list_bioc[,1]=="x"),]
	 
	 #this will cycle through all signification associations (row_col_signif) and plot that regression, pulling from row_col_signif
	if (p!=2) {
		pdf(width=10, height=10,file=paste0("regr_gen_clim_loose_",region,".pdf"))
		if (p==1) par(mfrow=c(4,4),mar=c(4,4,2,2),oma=c(2,3,1,1))
		if (p==3) par(mfrow=c(4,3),mar=c(4,4,2,2),oma=c(2,3,1,1))
		 for (i in 1:nrow(row_col_signif)){
		  eq1<-gen_sum_stats[pop_set[[p]],stat_list[row_col_signif[i,2]]]~clim[pop_set[[p]],row_col_signif[i,1]]
		 plot(eq1,col=point_colors[pop_set[[p]]],pch=point_shapes[pop_set[[p]]], xlab=list_bioc[row_col_signif[i,1],3], ylab=colnames(gen_sum_stats)[stat_list[row_col_signif[i,2]]])
		 abline(lm(eq1))
		 mtext(paste("R2= ",round(unlist(summary(lm(eq1))[8]),3),sep=""),side=3)
		  #text(eq1, labels = gen_sum_stats[pop_set[[p]],2]) #optional to add labels for pop names
		 }
		dev.off() 
	}

	 row_col_signif<-which( matrix(p.adjust(reg_pval,"BY"),nrow=12,ncol=5)<0.05,arr.ind=T)

	 
	  if (p==1) {pdf(width=10, height=4,file=paste0("regr_gen_clim_strict_",region,".pdf")); par(mfrow=c(1,4))}
	  if (p==2) {pdf(width=10, height=10,file=paste0("regr_gen_clim_strict_",region,".pdf")); par(mfrow=c(3,3),mar=c(4,4,2,2),oma=c(2,3,1,1))}
	  if (p==3) {pdf(width=10, height=4,file=paste0("regr_gen_clim_strict_",region,".pdf")); par(mfrow=c(1,3))}
	 for (i in 1:nrow(row_col_signif)){
	 eq1<-gen_sum_stats[pop_set[[p]],stat_list[row_col_signif[i,2]]]~clim[pop_set[[p]],row_col_signif[i,1]]
	 plot(eq1,col=point_colors[pop_set[[p]]],pch=point_shapes[pop_set[[p]]], xlab=list_bioc[row_col_signif[i,1],3], ylab=colnames(gen_sum_stats)[stat_list[row_col_signif[i,2]]])
	 abline(lm(eq1))
	 mtext(paste("R2= ",round(unlist(summary(lm(eq1))[8]),3),sep=""),side=3)
	  #text(eq1, labels = gen_sum_stats[pop_set[[p]],2]) #optional to add labels for pop names
	 }
	dev.off() 
}

