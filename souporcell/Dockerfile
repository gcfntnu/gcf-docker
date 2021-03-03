FROM gcfntnu/python-base-conda:4.9.2


RUN mamba install --quiet --yes \
    rust \
    numpy \
    scipy \
    pystan \
    pyvcf \
    pyfaidx \
    pysam \
    pyfasta \
    freebayes \
    samtools \
    tensorflow \
    bcftools \
    htslib \
    minimap2 && \    
    mamba clean --all


RUN mkdir /opt/vartrix
WORKDIR /opt/vartrix
RUN wget https://github.com/10XGenomics/vartrix/releases/download/v1.1.16/vartrix_linux
RUN chmod +x vartrix_linux 
RUN cp vartrix_linux /usr/local/bin/vartrix


WORKDIR /opt
RUN git clone https://github.com/gcfntnu/souporcell.git
RUN cd souporcell/souporcell && cargo build && cargo build --release
RUN cd souporcell/troublet && cargo build && cargo build --release

ENV PATH /opt/souporcell:$PATH
