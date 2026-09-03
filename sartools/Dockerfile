FROM gcfntnu/r-base-conda:4.5.3

RUN conda install --quiet --yes \
    bioconductor-deseq2 \
    bioconductor-edger \
    bioconductor-genefilter \
    bioconductor-tximport \
    r-data.table \
    r-optparse \
    r-xml2 \
    r-knitr \
    r-rmarkdown \
    r-systemfonts \
    r-textshaping \
    r-svglite \
    r-kableextra \
    r-remotes \
    pandoc && \
    conda clean --all --yes

ARG SARTOOLS_COMMIT=66b4b3d0249b15ec7f2bdad085d232d7c071d27d
RUN Rscript -e "remotes::install_github('PF2-pasteur-fr/SARTools@${SARTOOLS_COMMIT}', build_opts='--no-resave-data', upgrade='never')"
RUN Rscript -e "stopifnot(as.character(packageVersion('SARTools')) == '1.8.2'); library(SARTools); library(DESeq2); library(edgeR); library(kableExtra); stopifnot(nchar(as.character(rmarkdown::pandoc_version())) > 0)"
