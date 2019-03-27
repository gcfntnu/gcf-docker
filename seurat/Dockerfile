FROM gcfntnu/r-base:3.5.3

RUN R --slave -e "devtools::install_github(repo = 'ChristophH/sctransform', ref = 'develop')"
RUN R --slave -e "devtools::install_github(repo = 'satijalab/seurat', ref = 'release/3.0')"
RUN R --slave -e "devtools::install_github(repo = 'hhoeflin/hdf5r')"
RUN R --slave -e "devtools::install_github(repo = 'mojaveazure/loomR', ref = 'develop')"
RUN pip install umap-learn