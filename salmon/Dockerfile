FROM gcfntnu/python-base-conda:4.10.3

ENV SALMON_VER 1.5.2

RUN apt-get update --fix-missing &&  apt-get install -y \
    original-awk \
    cmake \
    build-essential \
    zlib1g-dev \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mamba install --quiet --yes \
    salmon=$SALMON_VER \
    terminus \
    bedtools \
    mashmap \
    samtools \
    git && \
    mamba clean -a 

WORKDIR /opt
RUN git clone https://github.com/COMBINE-lab/SalmonTools.git
RUN mkdir -p SalmonTools/_build
RUN cd SalmonTools/_build && cmake .. && make && make install
RUN chmod +x /opt/SalmonTools/scripts/*

ENV PATH /opt/SalmonTools/bin:/opt/SalmonTools/scripts:$PATH
