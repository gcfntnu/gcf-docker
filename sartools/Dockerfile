FROM gcfntnu/r-base-conda:4.0.2

ENV SARTOOLS_VER 1.7.3

RUN mamba install --quiet --yes \
    r-cairo \
    font-ttf-ubuntu \
    r-optparse \
    r-sartools=$SARTOOLS_VER && \
    mamba clean -ai
