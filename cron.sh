#!/bin/bash

BASE_DIR="$SNAP_COMMON/spread-cron"
STEP=300
FINAL_TIME=0
INITIAL_TIME=0

record_new_value(){
    message=$1
    new_value=$2
    git commit --allow-empty -m "$message ($new_value)"
    git push
}

check(){
    . "$BASE_DIR"/options

    if [ -z "$pattern_extractor" -o -z "$message" ]; then
        echo "Required fields pattern_extractor and message not found in ../options"
        exit 1
    fi

    new_value=$(eval "$pattern_extractor" | tr -d '\r')
    if [ -z "$new_value" ]; then
        echo "pattern extractor $pattern_extractor could not extract anything"
        exit 1
    fi

    total_commits=$(git rev-list --count HEAD)
    n=0
    while [ $n -lt $total_commits ]; do
        log_entry=$(git log HEAD~${n} --pretty=%B | head -1)
        if echo "$log_entry" | grep "^$message" ; then
            old_value=$( echo "$log_entry" | sed -e "s|$message (\(.*\))|\1|")
            if [ "$new_value" != "$old_value" ]; then
                record_new_value "$message" "$new_value"
            fi
            exit 0
        fi
        n=$((n+1))
    done
    # no previous recorded value found
    record_new_value "$message" "$new_value"
}

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
                ( check )
            fi
        done
        FINAL_TIME=$SECONDS
    fi
    sleep $((STEP - FINAL_TIME + INITIAL_TIME))
done
