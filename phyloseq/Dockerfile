FROM gcfntnu/r-base:4.1.2

RUN apt-get -y install libhdf5-dev

RUN pip install umap-learn

RUN install2.r --error effsize ggpubr gplots ggplot2 gridGraphics gridExtra RColorBrewer reshape2 robCompositions vegan  permute zCompositions 

RUN R --slave -e "install.packages('BiocManager');BiocManager::install(c('phyloseq', 'pcaMethods', 'edgeR', 'DESeq2'))"

RUN R --slave -e 'devtools::install_github("ikwak2/DrImpute")'
RUN R --slave -e 'devtools::install_github("Vivianstats/scImpute", ref = "47c843d");'
RUN R --slave -e "devtools::install_github(repo = 'hhoeflin/hdf5r')"
RUN R --slave -e "devtools::install_github(repo = 'mojaveazure/loomR', ref = 'develop')"

COPY ./ext ext 
RUN Rscript -e 'install.packages("ext/DiversitySeq_1.0.tar.gz")'
RUN Rscript -e 'install.packages("ext/GMPR_0.1.3.tar.gz")'
RUN rm -rf /tmp/downloaded_packages/ /tmp/*.rds