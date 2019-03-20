FROM continuumio/miniconda:4.5.12

ENV R_VER 3.5.1

RUN apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN conda update conda
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge

RUN conda install --quiet --yes \
    r-base==$R_VER \
    r-tidyverse \
    r-devtools \
    r-biocmanager && \
    conda clean -tipsy