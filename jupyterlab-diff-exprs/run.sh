#!/bin/bash

sudo docker run -v $(pwd):/tmp/work --net=host gcfntnu/jupyterlab-diff-exprs:1.1
