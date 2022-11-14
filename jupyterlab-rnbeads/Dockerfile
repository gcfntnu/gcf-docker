FROM gcfntnu/rnbeads:2.12.2

RUN mamba install -y -q \
  nodejs \
  pandoc \
  nbconvert \
  r-plotly \
  r-irkernel \
  r-htmlwidgets \
  jupyterlab && \
  mamba clean -ai

RUN mkdir /tmp/work
WORKDIR /tmp/work

#RUN R -e "IRkernel::installspec(name='ir43', display='R4.0.3', prefix='/opt/conda', user=FALSE)"

RUN export NODE_OPTIONS=--max-old-space-size=4096
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build
RUN jupyter labextension install jupyterlab-plotly --no-build
RUN jupyter labextension install plotlywidget --no-build
RUN jupyter lab build
RUN jupyter lab clean
RUN unset NODE_OPTIONS

CMD jupyter-lab --allow-root --port 9999 --no-browser 

RUN jupyter kernelspec list