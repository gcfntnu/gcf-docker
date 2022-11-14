FROM rocker/r-ver:4.2.1


RUN apt-get update -qq && apt-get install -y --no-install-recommends apt-utils && apt-get -y install \
  build-essential \
  libreadline-dev \
  git \
  zlib1g-dev \
  cmake \
  gfortran \
  tzdata \
  fonts-dejavu \
  python3-venv \
  libpcre++-dev \
  openjdk-8-jdk \
  libz-dev \
  libmagick++-dev \
  libhdf5-dev \
  libreadline-dev \
  liblzma-dev \
  libgit2-dev \
  libcgal-dev \
  libglu1-mesa-dev \
  libx11-dev \
  libxml2-dev \
  ghostscript \
  xdg-utils \
  libudunits2-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*


RUN R --slave -e "install.packages('BiocManager')"
RUN R --slave -e "BiocManager::install(c('keras', 'fishpond', 'argparse', 'caret', 'matrix'), update=TRUE, force=TRUE)"


RUN R --slave -e "keras::install_keras(method='auto')"

RUN git clone http://github.com/lkmklsmn/empty_nn
RUN R --slave -e "install.packages('empty_nn/EmptyNN_1.0.tar.gz', repos = NULL, type = 'source')"

