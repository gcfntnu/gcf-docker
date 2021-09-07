FROM gcfntnu/r-base-conda:4.0.5

#RUN mamba install --yes mysql-libs zstd
#RUN conda list

RUN mamba install  --yes \
    r-biocmanager \
    bioconductor-tximport \
    bioconductor-tximeta \
    bioconductor-rankprod \
    bioconductor-edaseq \
    bioconductor-pcatools \
    bioconductor-dittoseq \
    bioconductor-deformats \
    bioconductor-outrider \
    bioconductor-mixomics \
    bioconductor-dupradar \
    r-cairo \
    font-ttf-ubuntu \
    r-optparse \
    bioconductor-edger \
    r-plotly \
    r-locfdr \
    bioconductor-sva \
    bioconductor-ihw \	
    bioconductor-fishpond \
    bioconductor-drimseq \
    bioconductor-biobroom \
    bioconductor-sva \
    bioconductor-gwena \
    bioconductor-mixomics \
    bioconductor-deseq2 && \
    mamba clean -ai

RUN R --slave -e "BiocManager::install('GenomeInfoDbData', force=TRUE)"
RUN R --slave -e "devtools::install_github('yanlinlin82/ggvenn')"
RUN R --slave -e "devtools::install_github('QikeLi/iDEG', build_vignettes = TRUE)"