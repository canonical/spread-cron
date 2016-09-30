#!/bin/bash

BASE_DIR="$SNAP_DATA/spread-cron"
STEP=3000

while true; do
    if [ ! -d "$BASE_DIR" ]; then
        git clone git://github.com/snapcore/spread-cron
    fi
    cd "$BASE_DIR" || exit

    # run checker on each branch
    initial_time=$SECONDS
    for remote in $(git branch -r); do
        if [ "$remote" != "origin/HEAD" ] && [ "$remote" != "origin/master" ] && [ "$remote" != "->" ]; then
            branch="${remote#origin/}"
            git branch --track "$branch" "$remote";
            git checkout "$branch"
            git pull
            $BASE_DIR/checker/run
        fi
    done
    final_time=$SECONDS

    sleep $((STEP - final_time + initial_time))
done
