FROM gcfntnu/r-base:3.6.0
 
RUN R --slave -e "BiocManager::install(c('qvalue', 'limma', 'edgeR', 'DESeq2', 'DEXSeq', 'pasilla'))"
RUN R --slave -e "devtools::install_github('StoreyLab/subSeq')"
RUN R --slave -e "devtools::install_github('StoreyLab/superSeq', build_opts = c('--no-resave-data', '--no-manual'), build_vignettes = TRUE)"


