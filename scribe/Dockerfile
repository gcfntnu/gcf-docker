FROM gcfntnu/scanpy:1.4

RUN conda install --quiet --yes \
    cvxopt>=1.2.3 \
    pandas>=0.23.0\
    numpy>=1.14 \
    scipy>=1.0 \
    scikit-learn>=0.19.1 \
    statsmodels>=0.9.0 \
    scanpy>=1.3.3 \
    anndata>=0.6.18 \
    loompy>=2.0.12 \
    matplotlib>=2.2 \
    seaborn>=0.9.0 \
    networkx>=2.3 \
    r-devtools \
    setuptools && \
    conda clean -tipsy


RUN pip install pyccm

RUN pip install git+https://github.com/aristoteleo/Scribe-py

RUN R --slave -e "devtools::install_github(repo = 'cole-trapnell-lab/RANNinf')"
#RUN R --slave -e "devtools::install_github(repo = 'cole-trapnell-lab/Scribe')"

RUN conda install --quiet --yes \
  bioconductor-monocle \
  r-hiver \
  r-cowplot \
  r-lpsolveapi
  
RUN git clone https://github.com/cole-trapnell-lab/Scribe.git
RUN cd Scribe && R CMD INSTALL Scribe_0.1.tar.gz