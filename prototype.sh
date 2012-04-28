#!/bin/sh
set -e -v

# Setup a test repo
git clone git@github.com:johnjbarton/atopwi.git
cd atopwi

# git tx-clone [--name <projectName> ] <url> <branchname>  <remote_path> <local_path>
PROJECT_NAME="front-end"
REMOTE_URL="git@github.com:johnjbarton/front-end.git"
REMOTE_BRANCH="protocolExtension"
REMOTE_PATH="front_end/"
LOCAL_PATH="inspector/front_end"

LOCAL_BRANCH=`git symbolic-ref HEAD`

git checkout --orphan $REMOTE_PATH
git rm -rf .
git clone -b $REMOTE_BRANCH $REMOTE_URL


