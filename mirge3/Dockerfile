FROM gcfntnu/python-base-conda:4.10.3


RUN mamba install --yes \
    biopython \
    cutadapt \
    future \
    joblib \
    matplotlib \
    pandas \
    reportlab \
    samtools \
    scikit-learn \
    scipy \
    viennarna \
    bowtie \
    sra-tools \
    kmc 

RUN pip install mirge3
RUN pip install --upgrade mirge3


WORKDIR /tmp
RUN git clone https://github.com/XuanrZhang/miREC
RUN cd miREC && make && chmod +x miREC.sh