FROM jupyter/datascience-notebook:latest

USER root
RUN apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER $NB_UID
RUN conda update conda
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda update --all

RUN conda install --quiet --yes r-argparse r-biocmanager r-plotly r-devtools argparse && conda clean -tipsy

RUN conda install --quiet --yes -c plotly plotly plotly-orca plotly_express dash-table dash jupyterlab-dash colorlover && conda clean -tipsy

RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
    jupyter labextension install plotlywidget && \
    jupyter labextension install @jupyterlab/plotly-extension