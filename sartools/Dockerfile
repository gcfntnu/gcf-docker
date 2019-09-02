FROM gcfntnu/python-base-conda:3.7

ENV SARTOOLS_VER 1.6.9

RUN conda install --quiet --yes \
    r-optparse \
    r-sartools=$SARTOOLS_VER && \
    conda clean -tipsy
