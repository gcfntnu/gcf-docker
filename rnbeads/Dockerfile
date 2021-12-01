FROM gcfntnu/r-base:4.1.2


RUN R --slave -e "install.packages('doParallel', repos='http://cran.rstudio.com/')"
RUN R --slave -e "BiocManager::install(c('RnBeads', 'RnBeads.hg19', 'wateRmelon', 'impute', 'GLAD', 'LOLA', 'GOstats'), dependencies = TRUE)"
RUN R --slave -e "BiocManager::install(c('Gviz', 'missMethyl'))"

RUN apt update && apt -y install ghostscript  flatpak-xdg-utils