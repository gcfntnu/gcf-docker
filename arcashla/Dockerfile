## Load ubuntu

FROM ubuntu:19.10


## Environment variables

ENV SAMTOOLS_VERSION=1.9
ENV KALLISTO_VERSION=0.44.0
ENV BEDTOOLS_VERSION=2.27.1

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

## Update and install needed packages

RUN  apt-get update && 	apt-get install -y --no-install-recommends \
	bzip2 \
	git \
	curl \
	unzip \
	autoconf \
	wget \
    build-essential \
    cmake \
    libhdf5-dev \
    libnss-sss \
    zlib1g-dev \
    python \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-biopython \
    pigz \
    libcurl4-openssl-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libbz2-dev \
    liblzma-dev \
	coreutils \
	git-lfs
	
## Install python libraries

RUN pip3 install wheel==0.33.4
RUN pip3 install python-dateutil==2.7.3 
RUN pip3 install Cython==0.29.10
RUN pip3 install pytz==2019.1
RUN pip3 install pandas==0.23.0
RUN pip3 install scipy==1.1.0

## Install kallisto

WORKDIR /docker
RUN curl -SL --output v${KALLISTO_VERSION}.tar.gz https://github.com/pachterlab/kallisto/archive/v${KALLISTO_VERSION}.tar.gz
RUN tar -xzf v${KALLISTO_VERSION}.tar.gz
WORKDIR /docker/kallisto-${KALLISTO_VERSION}/ext/htslib
RUN autoheader
RUN autoconf
WORKDIR /docker/kallisto-${KALLISTO_VERSION}/build
RUN cmake .. && \
	make && \
	make install


## Install Samtools 

WORKDIR /docker
RUN curl -SL -o samtools-${SAMTOOLS_VERSION}.tar.bz2 https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2
RUN tar -xjf samtools-${SAMTOOLS_VERSION}.tar.bz2
WORKDIR /docker/samtools-${SAMTOOLS_VERSION}
RUN ./configure --prefix=/usr/local
RUN make && \
    make install

## Install Bedtools 

WORKDIR /docker
RUN curl -SL -o bedtools-${BEDTOOLS_VERSION}.tar.gz https://github.com/arq5x/bedtools2/archive/v${BEDTOOLS_VERSION}.tar.gz
RUN tar -xzf bedtools-${BEDTOOLS_VERSION}.tar.gz
WORKDIR /docker/bedtools2-${BEDTOOLS_VERSION}
RUN make
RUN cp -r bin/* /usr/local/bin/

## Install arcasHLA with database 3.37.0

RUN mkdir /software
WORKDIR /software
RUN git clone https://github.com/RabadanLab/arcasHLA.git
WORKDIR /software/arcasHLA
RUN git checkout 450e12c29f57be98bccf3bd092e306f8fc969946
RUN mkdir dat/IMGTHLA
RUN curl -SL -o dat/IMGTHLA/hla.dat https://github.com/ANHIG/IMGTHLA/raw/3370/hla.dat
RUN ./arcasHLA reference --rebuild --verbose
ENV PATH /software/arcasHLA:$PATH

## Clean up 

RUN rm -rf /docker
ENV PATH /usr/local/bin:$PATH

