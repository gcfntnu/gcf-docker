#!/bin/bash

sudo docker run -v $(pwd):/tmp/work --net=host gcfntnu/jupyterlab-scanpy
