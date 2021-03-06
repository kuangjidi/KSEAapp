#' The Complete KSEA App Analysis
#' 
#' Takes a formatted phoshoproteomics data input and performs KSEA calculations to infer relative kinase activities
#' 
#' @param KSData the Kinase-Substrate dataset uploaded from the file 
#'               prefaced with "PSP&NetworKIN_"
#'               available from github.com/casecpb/KSEA/
#' @param PX the experimental data file formatted exactly as described below;
#'           must have 6 columns in the exact order: Protein, Gene, Peptide, Residue.Both, p, FC;
#'           cannot have NA values, or else the entire peptide row is deleted;
#'           Description of each column in PX: 
#'           \itemize{
#'               \item{"Protein"}{ the Uniprot ID for the parent protein} 
#'               \item{"Gene"}{ the HUGO gene name for the parent protein} 
#'               \item{"Peptide"}{ the peptide sequence}
#'               \item{"Residue.Both"}{ all phosphosites from that peptide, separated by semicolons if applicable;
#'                                must be formatted as the single amino acid abbrev. with the residue position (e.g. S102)}
#'               \item{"p"}{ the p-value of that peptide (if none calculated, please write "NULL", cannot be NA)}
#'               \item{"FC"}{ the fold change (not log-transformed); usually the control sample is the denominator}
#'               }
#' @param NetworKIN a binary input of TRUE or FALSE, indicating whether or not to include NetworKIN predictions; 
#'                  NetworKIN = TRUE means inclusion of NetworKIN predictions
#' @param NetworKIN.cutoff a numeric value between 1 and infinity setting the minimum NetworKIN score 
#'                         (can be left out if NetworKIN = FALSE)
#' @param m.cutoff a numeric value between 0 and infinity indicating the min. # of substrates 
#'                 a kinase must have to be included in the bar plot output
#' @param p.cutoff a numeric value between 0 and 1 indicating the p-value cutoff for
#'                 indicating significant kinases in the bar plot
#'
#' @return creates the following outputs that are deposited into your working directory: 
#'         a bar plot highlighting key kinase results, a .csv file of all KSEA kinase scores, 
#'         and a .csv file listing all kinase-substrate relationships used for the calculations
#'         
#' @references 
#' Casado et al. (2013) Sci Signal. 6(268):rs6
#' 
#' Hornbeck et al. (2015) Nucleic Acids Res. 43:D512-20
#' 
#' Horn et al. (2014) Nature Methods 11(6):603-4
#' 
#' @examples 
#' KSEA.Complete(KSData, PX, NetworKIN=TRUE, NetworKIN.cutoff=5, m.cutoff=5, p.cutoff=0.01)
#' KSEA.Complete(KSData, PX, NetworKIN=FALSE, m.cutoff=2, p.cutoff=0.05)
#' 
#' @importFrom grDevices dev.off png tiff
#' @importFrom graphics barplot par
#' @importFrom stats aggregate complete.cases p.adjust pnorm sd
#' @importFrom utils write.csv
#' 
#' @export

#----------------------------#
# IMPORTANT OVERVIEW OF PX INPUT REQUIREMENTS

# PX input requirements:
# must have exact 6 columns in the following order: Protein, Gene, Peptide, Residue.Both, p, FC
# cannot have NA values, or else the entire peptide row is deleted

# Description of each column in PX: 
# - Protein = the Uniprot ID for the parent protein
# - Gene = the HUGO gene name for the parent protein
# - Peptide = the peptide sequence
# - Residue.Both = all phosphosites from that peptide, separated by semicolons if applicable; must be formatted as the single amino acid abbrev. with the residue position (e.g. S102)
# - p = the p-value of that peptide (if none calculated, please write "NULL", cannot be NA)
# - FC = the fold change (not log-transformed); usually recommended to have the control sample as the denominator
#----------------------------#

KSEA.Complete = function (KSData, PX, NetworKIN, NetworKIN.cutoff, m.cutoff, p.cutoff){
  
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
  # Process the input data files
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
  
  #--------------
  # Process the PX data file
  # Check if each peptide row has multiple phosphorylated residues and create new dataframe with a single residue per row
  
  if (length(grep(";", PX$Residue.Both))==0){
    new = PX
    colnames(new)[c(2,4)] = c("SUB_GENE", "SUB_MOD_RSD")
    new$log2FC = log2(abs(as.numeric(as.character(new$FC)))) # the as.numeric(as.character()) fixes an issue with the FC values as factors
    new = new[complete.cases(new$log2FC),]
  }
  
  else {
    double = PX[grep(";",PX$Residue.Both),]
    residues = as.character(double$Residue.Both)
    residues = as.matrix(residues, ncol = 1)
    split = strsplit(residues, split = ";")
    x = sapply(split, length)
    
    single = data.frame(Protein = rep(double$Protein, x), 
                        Gene = rep(double$Gene, x),
                        Peptide = rep(double$Peptide, x),
                        Residue.Both = unlist(split),
                        p = rep(double$p, x),
                        FC = rep(double$FC, x))
    
    # create new object of PX that has all residues in separate rows
    new = PX[-grep(";", PX$Residue.Both),]
    new = rbind(new, single)
    colnames(new)[c(2,4)] = c("SUB_GENE", "SUB_MOD_RSD")
    new$log2FC = log2(abs(as.numeric(as.character(new$FC)))) # the as.numeric(as.character()) fixes an issue with the FC values as factors
    new = new[complete.cases(new$log2FC),]
  }
  
  
  #----------------
  # Process KSData dataset based on user input (NetworKIN=T/F and NetworKIN cutoff score)
  
  if (NetworKIN == TRUE){
    KSData.filtered = KSData[grep("[a-z]", KSData$Source),]
    KSData.filtered = KSData.filtered[(KSData.filtered$networkin_score >= NetworKIN.cutoff),]
  }
  else{
    KSData.filtered = KSData[grep("PhosphoSitePlus", KSData$Source),]
  }
  
  #----------------
  # Extract KSData.filtered annotations that are only found in new
  
  KSData.dataset = merge(KSData.filtered, new)
  KSData.dataset = KSData.dataset[order(KSData.dataset$GENE),]
  KSData.dataset$Uniprot.noIsoform = sapply(KSData.dataset$KIN_ACC_ID, function(x) unlist(strsplit(as.character(x), split="-"))[1])
  # last expression collapses isoforms of the same protein for easy processing

  KSData.dataset.abbrev = KSData.dataset[,c(5,1,2,16:19,14)]
  colnames(KSData.dataset.abbrev) = c("Kinase.Gene", "Substrate.Gene", "Substrate.Mod", "Peptide", "p", "FC", "log2FC", "Source")
  KSData.dataset.abbrev = KSData.dataset.abbrev[order(KSData.dataset.abbrev$Kinase.Gene, KSData.dataset.abbrev$Substrate.Gene, KSData.dataset.abbrev$Substrate.Mod, KSData.dataset.abbrev$p),]
  
  # take the mean of the log2FC amongst phosphosite duplicates
  KSData.dataset.abbrev = aggregate(log2FC ~ Kinase.Gene+Substrate.Gene+Substrate.Mod+Source, data=KSData.dataset.abbrev, FUN=mean)
  
  KSData.dataset.abbrev = KSData.dataset.abbrev[order(KSData.dataset.abbrev$Kinase.Gene),]
  
  
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
  # Do analysis for KSEA
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
  
  kinase.list = as.vector(KSData.dataset.abbrev$Kinase.Gene)
  kinase.list = as.matrix(table(kinase.list))
  
  Mean.FC = aggregate(log2FC ~ Kinase.Gene, data=KSData.dataset.abbrev, FUN=mean)
  Mean.FC = Mean.FC[order(Mean.FC[,1]),]
  Mean.FC$mS = Mean.FC[,2]
  Mean.FC$Enrichment = Mean.FC$mS/abs(mean(new$log2FC, na.rm=T))
  Mean.FC$m = kinase.list
  Mean.FC$z.score = ((Mean.FC$mS- mean(new$log2FC, na.rm=T))*sqrt(Mean.FC$m))/sd(new$log2FC, na.rm=T)
  Mean.FC$p.value = pnorm(-abs(Mean.FC$z.score)) # 1-tailed p-value
  Mean.FC$FDR = p.adjust(Mean.FC$p.value, method="fdr")
  
  Mean.FC.filtered = Mean.FC[(Mean.FC$m >= m.cutoff),-2] # filter dataset by m.cutoff
  Mean.FC.filtered = Mean.FC.filtered[order(Mean.FC.filtered$z.score),]
  
  
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
  # Create Outputs
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
  
  #----------------
  # Create bar plot for Kinase z-score
  
  plot.height = length(Mean.FC.filtered$z.score)^0.55
  
  # create color coding according to the p.cutoff
  Mean.FC.filtered$color = "black"
  Mean.FC.filtered[(Mean.FC.filtered$p.value < p.cutoff)&(Mean.FC.filtered$z.score < 0),ncol(Mean.FC.filtered)] = "blue"
  Mean.FC.filtered[(Mean.FC.filtered$p.value < p.cutoff)&(Mean.FC.filtered$z.score > 0),ncol(Mean.FC.filtered)] = "red"
  
  tiff("KSEA Bar Plot.tiff",    
       width = 6*300,        
       height = 300*plot.height,
       res = 300, # 300 pixels per inch
       pointsize = 13)
  par(mai=c(1,1,.4,.4))
  barplot(as.numeric(Mean.FC.filtered$z.score), col=Mean.FC.filtered$color,
          border = NA,
          xpd=F, cex.names= .6, cex.axis = 0.8,
          xlab = "Kinase z-score",
          names.arg=Mean.FC.filtered$Kinase.Gene, horiz=T, las=1)
  dev.off()
  
  #----------------
  # Create tables
  
  write.csv(KSData.dataset.abbrev, file="Kinase-Substrate Links.csv", quote=F, row.names=F)
  write.csv(Mean.FC[order(Mean.FC$Kinase.Gene),-ncol(Mean.FC)], file="KSEA Kinase Scores.csv", quote=F, row.names=F)
  
}


