FROM gcfntnu/python-base-conda:3.7

ENV TXIMPORT_VER 1.14.0

RUN conda install --quiet --yes \
    r-argparse \
    r-readr \
    r-matrix \
    bioconductor-dropletutils \
    bioconductor-deseq2 \
    bioconductor-genomeinfodbdata \
    bioconductor-genomeinfodb \
    r-stringi \
    bioconductor-tximport==$TXIMPORT_VER && \
    conda clean -tipsy

RUN R --slave -e "BiocManager::install(rownames(installed.packages()), type='source', checkBuilt=TRUE)"