FROM gcfntnu/python-base-conda:4.10.3

ENV PATH /opt/miREC:$PATH

RUN mamba install --yes cutadapt
  
WORKDIR /opt
RUN git clone https://github.com/XuanrZhang/miREC
RUN cd miREC && make && chmod +x miREC.sh && chmod +x kmc*

