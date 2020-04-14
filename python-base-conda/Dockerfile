FROM continuumio/miniconda3:4.8.2

RUN apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN conda update conda
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda update --all

RUN conda install --quiet --yes pandas pyyaml && conda clean -tipsy
