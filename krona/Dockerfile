FROM gcfntnu/python-base-conda:22.11.1


ENV KRONA_VER 2.8.1

RUN conda install -y krona=$KRONA_VER biopython

RUN mkdir /scripts && cd /scripts && git clone https://github.com/jenniferlu717/KrakenTools.git

ENV PATH $PATH:/scripts/KrakenTools

