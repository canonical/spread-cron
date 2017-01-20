#!/bin/sh

# keep tests from master, checkout 2.21 and put tests from master in place
(
    cd target || exit
    cp -ar tests ..
    git fetch
    git checkout release/2.21
    rm -rf tests && mv ../tests .
)
