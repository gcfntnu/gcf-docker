FROM gcfntnu/build-base:22.04

RUN apt update && apt install -y readseq gawk artemis emboss openjdk-17-jdk openjdk-17-jre

WORKDIR /opt

COPY files/METAnnotatorX2-2.1.7.zip .

RUN unzip METAnnotatorX2-2.1.7.zip && mv Nalavalatautoril-METAnnotatorX2-5a5e0d6 METAnnotatorX2

WORKDIR METAnnotatorX2

RUN sh METAnnotatorX2_installer.sh


