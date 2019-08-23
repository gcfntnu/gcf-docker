FROM gcfntnu/build-base:latest

RUN git clone https://github.com/linsalrob/fastq-pair.git

RUN mkdir fastq-pair/build && cd fastq-pair/build && cmake ..
RUN cd fastq-pair/build && make && make install

