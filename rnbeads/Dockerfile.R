FROM gcfntnu/r-base:4.2.0

RUN apt update && apt -y install ghostscript  flatpak-xdg-utils  default-libmysqlclient-dev libxml2 libxml2-dev less  zip gzip curl wget

RUN R --slave -e "install.packages('doParallel', 'glmnet', repos='http://cran.rstudio.com/')"
RUN R --slave -e "BiocManager::install(c('RnBeads', 'RnBeads.hg19', 'RnBeads.hg38', 'RnBeads.mm10', 'RnBeads.rn5', 'wateRmelon', 'impute', 'GOstats', 'sva', 'wordcloud'), dependencies = TRUE)"
RUN R --slave -e "BiocManager::install(c('Gviz', 'missMethyl', 'rtracklayer', 'org.Hs.eg.db', 'isva', 'nlme', 'mclust', 'minfi'))"

WORKDIR /opt
RUN wget  https://cran.r-project.org/src/contrib/Archive/ggplot2/ggplot2_3.3.5.tar.gz
RUN R CMD INSTALL ggplot2_3.3.5.tar.gz
