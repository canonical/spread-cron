#!/bin/sh

# keep tests from master, build test binaries from master, checkout 2.21 and put tests from master in place
(
    cd target || exit
    go get ./tests/lib/snapbuild
    go get ./tests/lib/fakedevicesvc
    go get ./tests/lib/fakestore/cmd/fakestore
    cp -ar ./tests ./spread.yaml ..
    git fetch
    git checkout release/2.21
    rm -rf ./tests ./spread.yaml && mv ../tests ../spread.yaml .
)

# FIXME: remove this once the changes have landed on snapd
cp custom/prepare-project.sh target/tests/lib
