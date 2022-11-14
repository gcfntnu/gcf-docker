FROM gcfntnu/python-base-conda:3.7

RUN set -ex

ARG CRAN_MIRROR=https://cloud.r-project.org

RUN apt-get update -qq && apt-get -y install \
  build-essential \
  libreadline-dev \
  curl \
  cmake \
  tzdata \
  fonts-dejavu \
  python3-dev \
  python3-pip \
  libpcre++-dev \
  openjdk-8-jdk \
  libz-dev \
  libmagick++-dev \
  libhdf5-dev \
  libxml2-dev \
  libreadline-dev \
  liblzma-dev \
  libgit2-dev \
  libcgal-dev \
  libglu1-mesa-dev \
  libx11-dev \
  libudunits2-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN ln -s /bin/tar /bin/gtar
RUN R --slave -e "options(unzip='/usr/bin/unzip')"
RUN R CMD javareconf

RUN conda install --quiet --yes \
    cmake >=3.9 \
    autoconf \
    r-xml \
    r-tidyverse \
    tqdm && \
    conda clean -tipsy


WORKDIR /opt

RUN git clone https://github.com/HCBravoLab/yanagi.git
ENV PATH /opt/yanagi:$PATH


RUN git clone https://github.com/mgunady/Yanagi-count.git
WORKDIR /opt/Yanagi-count
RUN mkdir build
RUN cd build && cmake .. && make && make install
ENV PATH /opt/Yanagi-count/bin:$PATH


RUN R --slave -e "BiocManager::install(c('GenomeInfoDb', 'GenomeInfoDbData', 'GenomicFeatures', 'Rsamtools', 'gridExtra', 'tidyverse', 'reshape2'), update=TRUE)"
