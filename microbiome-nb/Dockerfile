FROM gcfntnu/jupyterlab-base:0.1

RUN conda install --yes \
  r-remotes \
  bioconductor-rhdf5 \
  bioconductor-rhdf5lib \	
  bioconductor-biomformat \
  bioconductor-phyloseq \
  bioconductor-microbiome \
  r-jsonlite \
  r-yaml \
  r-ggplot2 \
  r-cowplot \
  r-ggpubr \
  r-nlme \
  r-tidyverse \
  r-hmisc \
  r-ade4 \
  r-markdown \
  r-vctrs \
  r-vegan \
  r-zeallot && \
  conda clean -tipsy

RUN R --slave -e "options(unzip='internal'); Sys.setenv(TAR='/bin/tar')"

