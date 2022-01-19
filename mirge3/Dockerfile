FROM gcfntnu/python-base-conda:4.10.3

RUN apt-get update --fix-missing &&  apt-get install -y bowtie && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mamba install --yes \
  python=3.8 \
  samtools \
  sra-tools \
  mirge3 \
  kmc 
  
RUN pip install --no-deps miRge-build

WORKDIR /tmp
RUN git clone https://github.com/XuanrZhang/miREC
RUN cd miREC && make && chmod +x miREC.sh

