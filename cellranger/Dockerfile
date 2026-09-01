FROM gcfntnu/build-base:22.04

ENV CELLRANGER_VER=10.1.0
ENV PATH=/opt/cellranger-$CELLRANGER_VER:$PATH
ENV DEBIAN_FRONTEND=noninteractive

COPY files/cellranger-$CELLRANGER_VER.tar.gz /opt/cellranger-$CELLRANGER_VER.tar.gz

RUN apt-get update  &&  apt-get install -y ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN \
  cd /opt && \
  tar -xzvf cellranger-$CELLRANGER_VER.tar.gz && \
  rm -rf /opt/cellranger-$CELLRANGER_VER.tar.gz


RUN \
  mkdir -p /opt/gffread && \
  cd /opt/gffread && \
  git clone https://github.com/gpertea/gclib && \
  git clone https://github.com/gpertea/gffread && \
  cd gffread && \
  make release

ENV PATH /opt/gffread/gffread:$PATH

RUN cellranger --version && gffread --version