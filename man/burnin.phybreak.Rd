% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/burnin-phybreak.R
\name{burnin.phybreak}
\alias{burnin.phybreak}
\title{MCMC updating of a phybreak-object.}
\usage{
burnin.phybreak(phybreak.object, ncycles, keepphylo = NULL,
  phylotopology_only = 0)
}
\arguments{
\item{phybreak.object}{An object of class \code{phybreak}.}

\item{ncycles}{Number of iterations to be carried out. Each iteration does one update of all parameters and
tree updates with each host as focal host once.}

\item{keepphylo}{The proportion of tree updates keeping the phylotree intact. If there is more than one
sample per host, keepphylo should be 0. If set to NULL (default), this is done automatically, otherwise it is set to 0.2.}

\item{phylotopology_only}{The proportion of tree updates in which only the within-host minitree topology is sampled, and 
the transmission tree as well as coalescence times are kept unchanged.}
}
\value{
The \code{phybreak}-object provided as input, with variables and parameters changed due to the updating.
}
\description{
This function allows the MCMC chain to burn in. If used after samples have been taken (with \code{\link{sample.phybreak}}), 
  these samples will be returned unchanged in the output.
}
\examples{
#First create a phybreak-object
simulation <- sim.phybreak(obsize = 5)
MCMCstate <- phybreak(data = simulation)

MCMCstate <- burnin.phybreak(MCMCstate, ncycles = 50)
}
\references{
\href{http://dx.doi.org/10.1371/journal.pcbi.1005495}{Klinkenberg et al. (2017)} Simultaneous 
  inference of phylogenetic and transmission trees in infectious disease outbreaks. 
  \emph{PLoS Comput Biol}, \strong{13}(5): e1005495.
}
\author{
Don Klinkenberg \email{don@xs4all.nl}
}
