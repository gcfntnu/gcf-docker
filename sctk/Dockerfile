FROM gcfntnu/python-base-conda:3.9


#RUN apt-get update && \
#    apt-get install -y make zlib1g-dev libcurl4-openssl-dev libssl-dev \
#     libfontconfig1-dev libfreetype6-dev libfribidi-dev libharfbuzz-dev \
#     libjpeg-dev libpng-dev libtiff-dev pandoc libicu-dev libxml2-dev git \
#     libgit2-dev zlib1g-dev libicu-dev libcurl4-openssl-dev \
#     libglpk-dev libgmp3-dev libpng-dev
     
RUN mamba install --quiet --yes \
    scanpy=1.9.3 \
    numpy=1.25.2 \
    scipy=1.13.1 \
    leidenalg=0.10.0 \
    matplotlib \
    seaborn \
    scikit-learn \
    ipykernel \
    scikit-misc \
    ipykernel 
    
    #rpy2 \
    #r-biocmanager \
    #r-remotes 
    
#RUN pip install --no-cache-dir git+https://github.com/theislab/anndata2ri
RUN pip install --no-cache-dir git+https://github.com/Teichlab/sctk.git
RUN pip install --no-cache-dir marsilea
#RUN pip install --no-cache-dir piecewise-regression
#RUN pip install --no-cache-dir robustbase

#RUN R --slave -e "remotes::install_github('wmacnair/SampleQC')"
#RUN R --slave -e "remotes::install_github('cellgeni/schard')"

# rpy2
#ENV R_HOME /opt/conda/lib/R

