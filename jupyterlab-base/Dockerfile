FROM gcfntnu/python-base-conda:4.8.2

RUN apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    libreadline-dev \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN conda update conda
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda config --add channels plotly && \
    conda install mamba


RUN mamba install --yes \
    jupyterlab \
    readline \
    simplegeneric \
    ipywidgets  \
    r-argparse \
    r-biocmanager \
    plotly \
    plotly-orca \
    dash-table \
    dash \
    jupyterlab-dash \
    colorlover \
    r-plotly \
    r-devtools \
    r-tidyverse \
    rpy2 && \
    mamba clean --all


RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager plotlywidget
    
RUN jupyter lab build
