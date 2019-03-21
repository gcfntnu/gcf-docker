FROM gcfntnu/build-base:latest

ENV BCL2FASTQ_VER 2-20-0

RUN apt-get update --fix-missing &&  apt-get install -y alien && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN \ 
  wget http://emea.support.illumina.com/content/dam/illumina-support/documents/downloads/software/bcl2fastq/bcl2fastq2-v$BCL2FASTQ_VER-linux-x86-64.zip && \
  unzip bcl2fastq2-v$BCL2FASTQ_VER-linux-x86-64.zip  && \
  alien bcl2fastq2*.rpm && \
  dpkg -i bcl2fastq2*.deb && \
  rm bcl2fastq2*.deb bcl2fastq2*.rpm bcl2fastq2*.zip

