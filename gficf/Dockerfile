FROM gcfntnu/r-base:3.6.1

RUN apt-get update && apt-get install -y \
  libhdf5-dev \
  libgsl-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN gsl-config --version
RUN R --slave -e "devtools::install_github(repo = 'dibbelab/gficf')"
