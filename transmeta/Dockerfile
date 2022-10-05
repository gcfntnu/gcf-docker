FROM gcfntnu/build-base:22.04

RUN set -ex

RUN apt-get update -qq && apt-get -y install \
  libboost-all-dev \
  mpi-default-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*


WORKDIR /opt
RUN mkdir Boost
RUN mkdir BamTools
#RUN wget http://sourceforge.net/projects/boost/files/boost/1.47.0/boost_1_47_0.tar.bz2
#RUN tar xvjf boost_1_47_0.tar.bz2
#RUN cd boost_1_47_0 && ./bootstrap.sh && ./b2 install --prefix=/opt/Boost 

RUN git clone https://github.com/pezmaster31/bamtools.git
RUN cd bamtools && mkdir build
RUN cd bamtools/build && cmake -DCMAKE_INSTALL_PREFIX=/opt/BamTools .. && make && make install 

RUN git clone https://github.com/flatberg/TransMeta.git
RUN cd TransMeta/src
RUN cd TransMeta/src && make all BAMTOOLS_PATH=/opt/BamTools BOOST_PATH=/opt/Boost

ENV LD_LIBRARY_PATH /usr/local/lib:$LD_LIBRARY_PATH
#ENV LD_LIBRARY_PATH /opt/boost/lib/:$LD_LIBRARY_PATH
ENV PATH /opt/TransMeta/src/bin:$PATH
ENV PATH /opt/TransMeta/:$PATH