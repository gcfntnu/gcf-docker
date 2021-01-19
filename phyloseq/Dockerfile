FROM gcfntnu/r-base:4.0.3

RUN apt-get -y install libhdf5-dev

RUN pip install umap-learn

RUN R --slave -e "install.packages('BiocManager');BiocManager::install('phyloseq')"
RUN R --slave -e "devtools::install_github(repo = 'hhoeflin/hdf5r')"
RUN R --slave -e "devtools::install_github(repo = 'mojaveazure/loomR', ref = 'develop')"
