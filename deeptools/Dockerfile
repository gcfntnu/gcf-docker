FROM continuumio/miniconda:4.5.12

# use C.UTF-8 locale 
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# R pre-requisites ++
RUN apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget \
    ca-certificates \
    build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN conda update conda
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge

RUN conda install --quiet --yes deeptools openssl=1.0 && conda clean -tipsy