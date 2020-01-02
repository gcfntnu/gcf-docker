FROM gcfntnu/python-base-conda:3.7

RUN set -ex

RUN apt-get update -qq && apt-get -y install \
  wget \	    
  autoconf \
  build-essential && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN conda install --quiet --yes \
    scallop==0.10.4 \
    cufflinks && \
    conda clean -tipsy

WORKDIR opt
RUN wget https://github.com/Kingsford-Group/rnaseqtools/releases/download/v1.0.3/rnaseqtools-1.0.3.tar.gz
RUN tar xvzf rnaseqtools-1.0.3.tar.gz
WORKDIR /opt/rnaseqtools-1.0.3
RUN mkdir bin
RUN ./configure --prefix /opt/rnaseqtools-1.0.3 && make && make install

ENV PATH /opt/rnaseqtools-1.0.3/bin:$PATH