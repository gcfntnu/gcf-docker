FROM gcfntnu/python-base-conda:4.10.3

RUN set -ex

RUN apt-get update -qq && apt-get -y install \
  wget \	    
  autoconf \
  build-essential && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN mamba install  --yes \
    scallop==0.10.5 \
    perl-getopt-long && \
    mamba clean -ai

WORKDIR opt
RUN wget https://github.com/Kingsford-Group/rnaseqtools/releases/download/v1.0.4/rnaseqtools-1.0.4.tar.gz
RUN tar xvzf rnaseqtools-1.0.4.tar.gz
WORKDIR /opt/rnaseqtools-1.0.4
RUN mkdir bin
RUN ./configure --prefix /opt/rnaseqtools-1.0.4 && make && make install

RUN git clone https://github.com/Kingsford-Group/scallopadvising.git
ENV PATH /opt/scallopadvising/bin:$PATH


ENV PATH /opt/rnaseqtools-1.0.4/bin:$PATH