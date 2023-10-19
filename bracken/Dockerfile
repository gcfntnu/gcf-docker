FROM staphb/kraken2:2.1.3

WORKDIR /opt

ENV BRACKEN_VER 2.9

RUN apt update && apt install -y unzip python-is-python3
RUN wget https://github.com/jenniferlu717/Bracken/archive/refs/tags/v$BRACKEN_VER.zip && unzip v$BRACKEN_VER.zip

WORKDIR /opt/Bracken-$BRACKEN_VER

RUN ./install_bracken.sh

ENV PATH $PATH:/opt/Bracken-$BRACKEN_VER

