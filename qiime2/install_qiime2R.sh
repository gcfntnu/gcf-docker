mamba install -y --force-reinstall biom-format r-remotes bioconductor-rhdf5 bioconductor-biomformat bioconductor-phyloseq r-jsonlite r-yaml bioconductor-rhdf5 bioconductor-rhdf5lib r-tidyverse r-hmisc r-ade4 r-shiny r-nnet r-markdown r-vctrs r-zeallot r-data.table
mamba clean --all

R --slave -e "options(unzip='internal'); Sys.setenv(TAR='/bin/tar'); "

#remotes::install_github('jbisanz/qiime2R')"
