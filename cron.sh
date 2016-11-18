#!/bin/bash

BASE_DIR="$SNAP_COMMON/spread-cron"
STEP=3000
FINAL_TIME=0
INITIAL_TIME=0

while true; do
    # run checker on each branch
    if [ ! -f "$SNAP_COMMON/git-credentials" ]; then
        echo "No credentials file found, please run 'snap set spread-cron username=<username> password=<password>' with valid credentials of a github user with push priveleges for the snapcore/spread-cron repository."
    else
        if [ ! -d "$BASE_DIR" ]; then
            git clone https://github.com/snapcore/spread-cron.git "$BASE_DIR"
        fi
        cd "$BASE_DIR" || exit

        INITIAL_TIME=$SECONDS
        for remote in $(git branch -r); do
            if [ "$remote" != "origin/HEAD" ] && [ "$remote" != "origin/master" ] && [ "$remote" != "->" ]; then
                branch="${remote#origin/}"
                git branch --track "$branch" "$remote";
                git checkout "$branch"
                git pull
                $BASE_DIR/checker/run
            fi
        done
        FINAL_TIME=$SECONDS
    fi
    sleep $((STEP - FINAL_TIME + INITIAL_TIME))
done
