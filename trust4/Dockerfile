FROM gcfntnu/build-base:20.04

WORKDIR /opt
RUN git clone https://github.com/liulab-dfci/TRUST4.git
RUN cd TRUST4 && make
RUN chmod +x TRUST4/run-trust4
RUN ln -s TRUST4/run-trust4 /usr/local/bin/run-trust4