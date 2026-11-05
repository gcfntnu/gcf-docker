FROM gcfntnu/python-base-conda:4.10.3


RUN mamba install --quiet --yes openjdk

RUN mkdir /opt/rockhopper
WORKDIR /opt/rockhopper
RUN wget https://cs.wellesley.edu/~btjaden/Rockhopper/download/current/Rockhopper.jar

ENV PATH /opt/rockhopper:$PATH
