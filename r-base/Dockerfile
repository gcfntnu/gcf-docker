FROM bioconductor/bioconductor_docker:latest

ARG DEBIAN_FRONTEND=noninteractive
ARG CRAN_MIRROR=https://cloud.r-project.org

RUN apt-get update -qq && apt-get install -y --no-install-recommends apt-utils && apt-get -y install \
  build-essential \
  libreadline-dev \
  cmake \
  gfortran \
  tzdata \
  fonts-dejavu \
  python3-dev \
  python3-pip \
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

RUN ln -s /bin/tar /bin/gtar
RUN R --slave -e "options(unzip='/usr/bin/unzip')"
RUN R CMD javareconf

ADD install.R /tmp/
RUN R -f /tmp/install.R


RUN python3 -m pip install --no-cache-dir --upgrade pip && \
  python3 -m pip install --no-cache-dir --upgrade setuptools wheel && \
  python3 -m pip install --no-cache-dir --upgrade numpy pandas sphinx jinja2 tzlocal && \
  python3 -m pip install --no-cache-dir --upgrade rpy2