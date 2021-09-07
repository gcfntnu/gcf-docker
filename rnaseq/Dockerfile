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
    bioconductor-htsfilter \
    bioconductor-enhancedvolcano \
    bioconductor-complexheatmap \
    bioconductor-wiggleplotr \
    r-heatmaply \
    r-patchwork \
    r-autoplotly \
    r-fansi \
    r-cowplot \
    r-ggplotify \ 
    r-ggupset \
    r-ggfortify \
    r-ggalt \
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
    r-compositions \
    r-bayesm \
    r-sf \
    r-purrr \
    r-venn \
    bioconductor-biobroom \
    bioconductor-sva \
    bioconductor-gwena \
    bioconductor-mixomics \
    bioconductor-apeglm\
    bioconductor-genefilter \
    bioconductor-deseq2 && \
    mamba clean -ai

RUN R --slave -e "BiocManager::install('GenomeInfoDbData', force=TRUE)"
RUN R --slave -e "devtools::install_github('yanlinlin82/ggvenn')"
RUN R --slave -e "devtools::install_github('QikeLi/iDEG', build_vignettes = TRUE)"
RUN R --slave -e "devtools::install_github('skvanburen/CompDTUReg')"
RUN R --slave -e "install.packages('ashr',  repos='http://cran.rstudio.com/')"
RUN R --slave -e "devtools::install_github('gaospecial/ggVennDiagram')"