#!/bin/sh

# keep tests from master, checkout 2.21 and put tests from master in place
(
    cd target || exit
    cp -ar ./tests ./spread.yaml ..
    git fetch
    git checkout release/2.21
    rm -rf ./tests ./spread.yaml && mv ../tests ../spread.yaml .
)
