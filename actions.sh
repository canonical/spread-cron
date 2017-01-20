#!/bin/sh

# keep tests from master, build test binaries from master, checkout 2.21 and put tests from master in place
(
    cd target || exit
    mkdir -p ./tests/bin
    go get ./tests/lib/snapbuild
    cp $GOPATH/bin/snapbuild ./tests/bin
    go get ./tests/lib/fakedevicesvc
    cp $GOPATH/bin/fakedevicesvc ./tests/bin
    go get ./tests/lib/fakestore/cmd/fakestore
    cp $GOPATH/bin/fakestore ./tests/bin
    cp -ar ./tests ./spread.yaml ..
    git fetch
    git checkout release/2.21
    rm -rf ./tests ./spread.yaml && mv ../tests ../spread.yaml .
)

# FIXME: remove this once the changes have landed on snapd
cp custom/prepare-project.sh target/tests/lib
