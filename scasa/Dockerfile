FROM gcfntnu/r-base-conda:4.1.1

RUN mamba install --quiet --yes salmon=1.6.0 gffread gtfparse

RUN pip --no-cache-dir install vpolo

WORKDIR /opt
RUN wget https://github.com/eudoraleer/scasa/releases/download/scasa.v1.0.0/scasa_v1.0.0.tar.gz && \
    tar -xzvf scasa_v1.0.0.tar.gz

ENV PATH=$PATH:/opt/scasa

WORKDIR /test
RUN wget https://www.dropbox.com/s/gsi8x4fshbn0p11/Test_Dataset.tar.gz && \
    tar xvzf Test_Dataset.tar.gz

RUN wget https://www.dropbox.com/s/xoa6yl562a5lv35/refMrna.fa.gz?dl=1

WORKDIR /test/Test_Dataset
COPY files/refMrna.fa.gz /test/

RUN scasa --fastq Sample_01_S1_L001_R1_001.fastq,Sample_01_S1_L001_R2_001.fastq \
    --ref /test/refMrna.fa.gz  \
    --whitelist Sample_01_Whitelist.txt \
    --nthreads 4

