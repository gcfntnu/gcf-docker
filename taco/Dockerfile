FROM gcfntnu/python-base-conda:3.7

RUN set -ex

RUN conda install --quiet --yes \
    taco==0.7.3  \
    r-base \
    cpat \
    numpy \
    pysam && \
    conda clean -tipsy
