FROM gcfntnu/r-base-conda:4.0.5

RUN mamba install --quiet --yes \
    bioconductor-tximport \
    bioconductor-tximeta \
    r-cairo \
    font-ttf-ubuntu \
    r-optparse \
    bioconductor-edger \
    r-plotly \
    bioconductor-sva \
    bioconductor-gwena \
    bioconductor-mixomics \
    bioconductor-deseq2 && \
    mamba clean -ai

RUN R --slave -e "devtools::install_github('yanlinlin82/ggvenn')"