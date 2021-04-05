#!/bin/sh

set -x

GOOGLE_ACTION="$1"
GOOGLE_TASK="$2"

if [ -z "$GOOGLE_ACTION" ]; then
	echo "Google action not defined, exiting..."
	exit 1
fi
if [ -z "$GOOGLE_TASK" ]; then
	echo "Google task not defined, exiting..."
	exit 1
fi

CURR_DIR="$(pwd)"
TMP_IMAGE_ID="$(date +%N)"
SNAPD_DIR="$CURR_DIR/snapd"
SPREAD_IMAGES_DIR="$CURR_DIR/spread-images"

# Prepare spread-images project
git clone https://github.com/snapcore/spread-images "$SPREAD_IMAGES_DIR"
mv sa.json "$SPREAD_IMAGES_DIR/sa.json"

# Prepare snapd project
git clone https://github.com/snapcore/snapd.git "$SNAPD_DIR"
cd "$SNAPD_DIR"
# FAILED
# Author: Michael Vogt <mvo@ubuntu.com>  2021-03-23 08:08:46
# git checkout 7aa7417ebe85ee489f686c18919518e57ec3306e

# Author: Maciej Borzecki <maciej.zenon.borzecki@canonical.com> Tue Mar 16 16:19:50 2021 +0100
# git checkout f0a175e88a32783a657b6f4141183c6309de1daf

# Author: Samuele Pedroni <pedronis@lucediurna.net> Wed Mar 10 14:14:54 2021 +0100
# git checkout f3d9f94d54b93fa63a86f3ac849299f3f735d4b9

# Author: Maciej Borzecki <maciej.zenon.borzecki@canonical.com> Wed Mar 3 12:54:58 2021 +0100
#git checkout ef9406cf8f805fbb7964a0498fe7e7b392e9c9db

# Author: Ian Johnson <ian.johnson@canonical.com> Thu Feb 25 21:47:56 2021 -0600
# git checkout eb9eb615c79aeb8a52919bebc4be8e205a88bd44

# Author: Ian Johnson <ian.johnson@canonical.com> Fri Feb 12 13:21:51 2021 -0600
#git checkout b7defb82848c316e394526cfe2975b0337ed98ae

# Author: Sergio Cazzolato <sergiocazzolato@gmail.com> Mon Feb 15 05:28:50 2021 -0300
git checkout b59f0dcc8a19dcbfc61415ebc12b8a27317a4526

cd ..


# Get the images variables to use:
# SOURCE_SYSTEM: source system for the GOOGLE_TASK
# TARGET_SYSTEM: target system for the GOOGLE_TASK
# RUN_SNAPD: true when snapd tests have to pass to publish the image
. "$SPREAD_IMAGES_DIR/lib/google_task.sh"

# Run spread-images task
cd "$SPREAD_IMAGES_DIR"
if [ "$RUN_SNAPD" = "true" ]; then
	echo "Running spread-images task and creating tmp image"
    if ! SPREAD_TMP_IMAGE_ID="$TMP_IMAGE_ID" spread "google:${SOURCE_SYSTEM}:tasks/google/${GOOGLE_ACTION}/${GOOGLE_TASK}"; then
		echo "Spread images task failed, exiting..."
		exit 1
	fi
else
	echo "Running spread-images task and creating final image"
	if ! spread "google:${SOURCE_SYSTEM}:tasks/google/${GOOGLE_ACTION}/${GOOGLE_TASK}"; then
		echo "Spread images task failed, exiting..."
		exit 1
	fi
	exit
fi

# run snapd tests
echo "Configuring target image"
if ! python3 "$SPREAD_IMAGES_DIR/lib/tools/update_spread_yaml.py" "$SNAPD_DIR/spread.yaml" "google" "$TARGET_SYSTEM" "tmp-${TMP_IMAGE_ID}" "8"; then
	echo "Failed to update spread.yaml, exiting..."
	exit 1
fi

cd "$SNAPD_DIR"
PUBLISH_IMAGE=false
if spread "google:${TARGET_SYSTEM}"; then
	PUBLISH_IMAGE=true
fi

# Publish the final image and clean the temporal one
cd "$SPREAD_IMAGES_DIR"
if [ "$PUBLISH_IMAGE" = true ]; then
	SPREAD_TMP_IMAGE_ID="$TMP_IMAGE_ID" SPREAD_TARGET_SYSTEM=$TARGET_SYSTEM spread "google:${SOURCE_SYSTEM}:tasks/google/common/publish-tmp-image"
else
	SPREAD_TMP_IMAGE_ID="$TMP_IMAGE_ID" spread "google:${SOURCE_SYSTEM}:tasks/google/common/remove-tmp-image"
	exit 1
fi