FROM gcfntnu/build-base:latest

ENV BCL2FASTQ_VER 2-20-0

RUN apt-get update --fix-missing &&  apt-get install -y alien && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY files/bcl2fastq2-v2.20.0.422-Linux-x86_64.rpm /tmp
RUN alien -i /tmp/bcl2fastq2-v2.20.0.422-Linux-x86_64.rpm

