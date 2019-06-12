FROM jupyter/scipy-notebook:latest

USER root
RUN apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    libreadline-dev \
    less \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER $NB_UID
RUN conda update conda
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda update --all


RUN conda install --quiet --yes \
    libgfortran \
    readline \
    simplegeneric \
    ipywidgets>=7.2 \
    r-argparse \
    r-biocmanager \
    plotly \
    r-plotly \
    r-devtools \
    r-tidyverse \
    rpy2 \
    argparse && \
    conda clean -tipsy

RUN conda install --quiet --yes -c plotly plotly plotly-orca plotly_express dash-table dash jupyterlab-dash colorlover && conda clean -tipsy



RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build && \
    jupyter labextension install plotlywidget --no-build && \
    jupyter labextension install @jupyterlab/plotly-extension --no-build && \
    jupyter lab build

RUN npm dedupe