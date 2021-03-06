### calculate the log-likelihood ###



#' Log-likelihood of a phybreak-object.
#' 
#' The likelihood of a \code{phybreak}-object is calculated, with the option to include or exclude parts of the 
#' likelihood for genetic data, phylogenetic tree (within-host model), sampling times and generation times.
#' 
#' The sequence likelihood is calculated by Felsenstein's pruning algorithm, assuming a prior probability of 0.25 
#' for each nucleotide. The within-host likelihood is the likelihood of coalescence times given the within-host model 
#' and slope. The generation interval and sampling interval likelihood are log-densities of the gamma distributions 
#' for these variables.
#' 
#' @param object An object of class \code{phybreak}.
#' @param genetic Whether to include the likelihood of the mutation model.
#' @param withinhost Whether to include the likelihood of within-host (coalescent) model.
#' @param sampling Whether to include the likelihood of the sampling model (sampling intervals).
#' @param generation Whether to include the likelihood of the transmission model (generation intervals).
#' @param ... Some methods for this generic require additional arguments. None are used in this method.
#' @return The log-likelihood as an object of class logLik.
#' @author Don Klinkenberg \email{don@@xs4all.nl}
#' @references \href{http://dx.doi.org/10.1371/journal.pcbi.1005495}{Klinkenberg et al. (2017)} Simultaneous 
#'   inference of phylogenetic and transmission trees in infectious disease outbreaks. 
#'   \emph{PLoS Comput Biol}, \strong{13}(5): e1005495.
#' @examples 
#' #First build a phybreak-object containing samples.
#' simulation <- sim.phybreak(obsize = 5)
#' MCMCstate <- phybreak(data = simulation)
#' logLik(MCMCstate)
#' 
#' MCMCstate <- burnin.phybreak(MCMCstate, ncycles = 20)
#' logLik(MCMCstate)
#' 
#' tree0 <- get.phylo(MCMCstate)
#' seqdata <- get.seqdata(MCMCstate)
#' pml(tree0, seqdata, rate = 0.75*get.parameters(MCMCstate)["mu"]) 
#' logLik(MCMCstate, genetic = TRUE, withinhost = FALSE, 
#'        sampling = FALSE, generation = FALSE) #should give the same result as 'pml'
#' @export
logLik.phybreak <- function(object, genetic = TRUE, withinhost = TRUE, sampling = TRUE, generation = TRUE, ...) {
    res <- 0
    if (genetic) {
        res <- res + with(object, .likseq(matrix(unlist(d$sequences), ncol = d$nsamples), 
                                          attr(d$sequences, "weight"), 
                                          v$nodeparents, v$nodetimes, p$mu, d$nsamples))
    }
    if (generation) {
        res <- res + with(object, .lik.gentimes(p$obs, d$nsamples, p$shape.gen, p$mean.gen, v$nodetimes, v$nodehosts))
    }
    if (sampling) {
        res <- res + with(object, .lik.sampletimes(p$obs, d$nsamples, p$shape.sample, p$mean.sample, v$nodetimes))
    }
    if (withinhost) {
        res <- res + with(object, .lik.coaltimes(p$obs, p$wh.model, p$wh.slope, v$nodetimes, v$nodehosts, v$nodetypes))
    }
    attributes(res) <- list(
      nobs = object$p$obs,
      df = 1 + object$h$est.mG + object$h$est.mS + object$h$est.wh,
      genetic = genetic, withinhost = withinhost, sampling = sampling, generation = generation
    )
    class(res) <- "logLik"
    return(res)
}


### calculate the log-likelihood of sampling intervals 
.lik.gentimes <- function(obs, nsamples, shapeG, meanG, nodetimes, nodehosts) {
  nt <- nodetimes[2 * nsamples - 1 + 1:obs]
  nh <- nodehosts[2 * nsamples - 1 + 1:obs]
    sum(dgamma(nt[nh > 0] - 
                 nt[nh[nh > 0]], 
               shape = shapeG, scale = meanG/shapeG, log = TRUE))
}

### calculate the log-likelihood of generation intervals 
.lik.sampletimes <- function(obs, nsamples, shapeS, meanS, nodetimes) {
    sum(dgamma(nodetimes[1:obs] - nodetimes[2 * nsamples - 1 + 1:obs], shape = shapeS, scale = meanS/shapeS, log = TRUE))
}

### calculate the log-likelihood of coalescent intervals 
.lik.coaltimes <- function(obs, wh.model, slope, nodetimes, nodehosts, nodetypes) {
    if (wh.model == 1 || wh.model == 2) 
        return(0)
    
    coalnodes <- nodetypes == "c"
    orderednodes <- order(nodehosts, nodetimes)
    orderedtouse <- orderednodes[c(duplicated(nodehosts[orderednodes])[-1], FALSE)]
    # only use hosts with secondary infections
    
    ## make vectors with information on intervals between nodes
    coalno <- c(FALSE, head(coalnodes[orderedtouse], -1))  #interval starts with coalescence
    nodeho <- nodehosts[orderedtouse]  #host in which interval resides
    coalmultipliers <- choose(2 + cumsum(2 * coalno - 1), 2)  #coalescence coefficient
    
    ## from t to tau (time since infection)
    whtimes <- nodetimes - c(0, tail(nodetimes, obs))[1 + nodehosts]
    
    noderates <- 1/(slope * whtimes[orderedtouse])
    # coalescence rate (per pair of lineages)
    nodeescrates <- log(whtimes[orderedtouse])/(slope)
    # cumulative coalescence rate since infection of host (per pair of lineages)
    
    
    escratediffs <- nodeescrates - c(0, head(nodeescrates, -1))
    escratediffs[!duplicated(nodeho)] <- nodeescrates[!duplicated(nodeho)]
    # cumulative coalescence rate within interval (per pair of lineages)
    
    
    ## First: coalescence rates at coalescence nodes
    logcoalrates <- log(noderates[c(coalno[-1], FALSE)])
    
    # Second: probability to escape coalescence in all intervals
    logescapes <- -escratediffs * coalmultipliers
    
    
    return(sum(logcoalrates) + sum(logescapes))
    
}
