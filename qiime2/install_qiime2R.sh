conda install r-remotes bioconductor-rhdf5 bioconductor-biomformat bioconductor-phyloseq r-jsonlite r-yaml bioconductor-rhdf5 bioconductor-rhdf5lib r-tidyverse r-hmisc r-ade4 r-shiny r-nnet r-markdown r-vctrs r-zeallot r-remotes
conda clean -tipsy

R --slave -e "options(unzip='internal'); Sys.setenv(TAR='/bin/tar'); remotes::install_github('jbisanz/qiime2R')"
