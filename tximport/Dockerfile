FROM gcfntnu/python-base-conda:4.10.3

ENV TXIMPORT_VER 1.18.0
ENV TXIMETA_VER 1.12.0

RUN mamba install --quiet --yes \
    r-argparse \
    r-readr \
    r-matrix \
    r-data.table \
    bioconductor-tximeta \
    bioconductor-deseq2 \
    bioconductor-genomeinfodbdata \
    bioconductor-genomeinfodb \
    r-stringi \
    bioconductor-tximport=$TXIMPORT_VER && \
    mamba clean --all

RUN R --slave -e "BiocManager::install(rownames(installed.packages()), type='source', checkBuilt=TRUE)"