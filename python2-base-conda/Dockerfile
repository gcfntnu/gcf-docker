FROM continuumio/miniconda2:4.5.12

RUN apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    build-essential \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN conda update conda
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge

RUN conda install --quiet --yes pandas argparse && conda clean -tipsy