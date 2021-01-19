FROM gcfntnu/build-base:20.04

WORKDIR /opt/

RUN git clone https://github.com/bioinformatics-polito/BioSeqZip.git bioseqzip

RUN mkdir bioseqzip/build
RUN cd bioseqzip/build && cmake .. -DCMAKE_BUILD_TYPE=Release && make && cp apps/bioseqzip* /usr/local/bin