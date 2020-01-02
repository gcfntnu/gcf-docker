FROM gcfntnu/build-base:latest

RUN apt install libpthread-stubs0-dev

WORKDIR /opt
RUN git clone https://github.com/splicebox/PsiCLASS.git
RUN cd PsiCLASS && make

WORKDIR /opt/PsiCLASS

ENV PATH "/opt/PsiCLASS":$PATH