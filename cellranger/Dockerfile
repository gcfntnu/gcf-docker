FROM gcfntnu/build-base:22.04

ENV CELLRANGER_VER 7.2.0
ENV PATH /opt/cellranger-$CELLRANGER_VER:$PATH

COPY files/cellranger-$CELLRANGER_VER.tar.gz /opt/cellranger-$CELLRANGER_VER.tar.gz

RUN apt update  &&  apt install -y ca-certificates && \
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
