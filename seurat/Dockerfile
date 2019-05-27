FROM gcfntnu/r-base:3.6.0

RUN apt-get -y install libhdf5-dev

RUN pip install umap-learn

RUN R --slave -e "devtools::install_github(repo = 'ChristophH/sctransform', ref = 'develop')"
RUN R --slave -e "devtools::install_github(repo = 'satijalab/seurat', ref = 'develop')"
RUN R --slave -e "devtools::install_github(repo = 'hhoeflin/hdf5r')"
RUN R --slave -e "devtools::install_github(repo = 'mojaveazure/loomR', ref = 'develop')"

