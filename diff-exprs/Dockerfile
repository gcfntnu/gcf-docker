FROM gcfntnu/r-base-conda:4.0.5

RUN mamba install --quiet --yes \
    bioconductor-tximport \
    bioconductor-tximeta \
    r-cairo \
    font-ttf-ubuntu \
    bioconductor-edger \
    r-plotly \
    r-locfdr \
    r-pheatmap \
    bioconductor-genefilter \
    bioconductor-enhancedvolcano \
    bioconductor-sva \
    bioconductor-ihw \
    bioconductor-fishpond \
    bioconductor-drimseq \
    bioconductor-biobroom \
    bioconductor-mixomics \
    r-heatmaply \
    bioconductor-deseq2 && \
    mamba clean -ai

RUN R --slave -e "install.packages('ashr',  repos='http://cran.rstudio.com/')"
RUN R --slave -e "devtools::install_github('QikeLi/iDEG', build_vignettes = TRUE)"
RUN R --slave -e "devtools::install_github('yanlinlin82/ggvenn')"
RUN R --slave -e "BiocManager::install('apeglm')"