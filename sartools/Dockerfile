FROM gcfntnu/r-base-conda:4.0.4

ENV SARTOOLS_VER 1.7.3

RUN mamba install --quiet --yes \
    bioconductor-tximport \
    bioconductor-tximeta \
    r-cairo \
    font-ttf-ubuntu \
    r-optparse \
    r-sartools=$SARTOOLS_VER && \
    mamba clean -ai
