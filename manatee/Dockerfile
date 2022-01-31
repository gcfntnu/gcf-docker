FROM gcfntnu/python-base-conda:4.10.3

ENV PATH /opt/Manatee:$PATH

RUN apt-get update --fix-missing &&  apt-get install -y \
    bzip2 \
    perl \
    libarchive-extract-perl \
    cpanminus \
    gcc-multilib \
    dos2unix \
    sed && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mamba install --yes \
  samtools \
  bowtie
 
RUN cpanm install Set::IntervalTree Getopt::Long

  
WORKDIR /opt
RUN git clone https://github.com/jehandzlik/Manatee.git
RUN cd Manatee && chmod +x manatee

