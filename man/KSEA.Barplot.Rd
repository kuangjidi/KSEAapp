% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/KSEA.Barplot.R
\name{KSEA.Barplot}
\alias{KSEA.Barplot}
\title{The KSEA App Analysis (KSEA Bar Plot Only)}
\usage{
KSEA.Barplot(KSData, PX, NetworKIN, NetworKIN.cutoff, m.cutoff, p.cutoff,
  export)
}
\arguments{
\item{KSData}{the Kinase-Substrate dataset uploaded from the file 
prefaced with "PSP&NetworKIN_"
available from github.com/casecpb/KSEA/}

\item{PX}{the experimental data file formatted as described in the KSEA.Complete() documentation}

\item{NetworKIN}{a binary input of TRUE or FALSE, indicating whether or not to include NetworKIN predictions; 
NetworKIN = TRUE means inclusion of NetworKIN predictions}

\item{NetworKIN.cutoff}{a numeric value between 1 and infinity setting the 
minimum NetworKIN score (can be left out if NetworKIN = FALSE)}

\item{m.cutoff}{a numeric value between 0 and infinity indicating the min. # of substrates 
a kinase must have to be included in the bar plot output}

\item{p.cutoff}{a numeric value between 0 and 1 indicating the p-value cutoff 
for indicating significant kinases in the bar plot}

\item{export}{a binary input of TRUE or FALSE, indicating whether or not 
to export the bar plot as a .tiff image into the working directory}
}
\value{
creates the bar plot output highlighting key kinase results
}
\description{
Takes a formatted phoshoproteomics data input and returns just the summary bar plot of kinase scores
}
\examples{
KSEA.Barplot(KSData, PX, NetworKIN=TRUE, NetworKIN.cutoff=5, 
             m.cutoff=5, p.cutoff=0.01, export=FALSE)
KSEA.Barplot(KSData, PX, NetworKIN=TRUE, NetworKIN.cutoff=5, 
             m.cutoff=8, p.cutoff=0.05, export=TRUE)
KSEA.Barplot(KSData, PX, NetworKIN=FALSE, m.cutoff=2, p.cutoff=0.05, export=TRUE)

}
\references{
Casado et al. (2013) Sci Signal. 6(268):rs6

Hornbeck et al. (2015) Nucleic Acids Res. 43:D512-20

Horn et al. (2014) Nature Methods 11(6):603-4
}
