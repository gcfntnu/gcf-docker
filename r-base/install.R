# copied from bioconductor dockerfiles (relase/core)

if ("BiocManager" %in% rownames(installed.packages()))
	remove.packages("BiocManager")

install.packages("BiocManager", repos="https://cran.rstudio.com")
#install.packages("devtools", repos="https://cran.rstudio.com")
#devtools::install_github("Bioconductor/BiocManager")
library(BiocManager)

if(BiocManager::version() != "3.8"){
    BiocManager::install(version="3.8",
                         update=TRUE, ask=FALSE)
}

builtins <- c("Matrix", "KernSmooth", "mgcv")

for (builtin in builtins)
    if (!suppressWarnings(require(builtin, character.only=TRUE)))
        suppressWarnings(BiocManager::install(builtin,
                                              version="3.8",
                                              update=TRUE, ask=FALSE))

pkgs <- c(
    "OrganismDbi",
    "ExperimentHub",
    "Biobase",
    "BiocParallel",
    "biomaRt",
    "Biostrings",
    "BSgenome",
    "ShortRead",
    "IRanges",
    "GenomicRanges",
    "GenomicAlignments",
    "GenomicFeatures",
    "SummarizedExperiment",
    "DelayedArray"
    )

ap.db <- available.packages(contrib.url(BiocManager::repositories()))
ap <- rownames(ap.db)
fnd <- pkgs %in% ap
pkgs_to_install <- pkgs[fnd]

ok <- BiocManager::install(pkgs_to_install, update=FALSE, ask=FALSE) %in% rownames(installed.packages())

if (!all(fnd))
    message("Packages not found in a valid repository (skipped):\n  ",
            paste(pkgs[!fnd], collapse="  \n  "))
if (!all(ok))
    stop("Failed to install:\n  ",
         paste(pkgs_to_install[!ok], collapse="  \n  "))

suppressWarnings(BiocManager::install(update=TRUE, ask=FALSE))