FROM gcfntnu/python-base-conda:4.10.3

ENV PATH /opt/miREC:$PATH

RUN mamba install --yes cutadapt kmc
  
WORKDIR /opt
RUN git clone https://github.com/XuanrZhang/miREC
WORKDIR /opt/miREC
RUN make && chmod +x miREC.sh && chmod +x kmc*
COPY miREC_docker.sh . 
RUN chmod +x miREC_docker.sh