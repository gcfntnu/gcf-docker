FROM gcfntnu/python-base-conda:4.8.2

ENV SARTOOLS_VER 1.7.3

RUN mamba install --quiet --yes \
    mscorefonts \
    fonts-conda-ecosystem \
    r-essentials \
    r-optparse \
    r-sartools=$SARTOOLS_VER && \
    mamba clean -ai
