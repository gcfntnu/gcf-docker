FROM gcfntnu/build-base:latest


RUN apt-get update && \
    apt-get install -y --no-install-recommends git zlib1g-dev && \
    apt-get clean

WORKDIR /opt
RUN git clone https://github.com/Kingsford-Group/sad.git
RUN chmod +x sad/install.sh
RUN cd sad/ && ./install.sh
ARG PKG_CONFIG_PATH=/opt/sad/external/pkgconfig:${PKG_CONFIG_PATH}
RUN echo "O $PKG_CONFIG_PATH"
RUN ls -alh /opt/sad/external/pkgconfig
RUN cd sad/ && make
ENV PATH /opt/sad/bin:${PATH}
RUN ls -alh /opt/sad