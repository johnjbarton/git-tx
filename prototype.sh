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

LOCAL_BRANCH=`git symbolic-ref HEAD | sed -e 's/^.*\///'`

git checkout --orphan $PROJECT_NAME
git rm -rf .
git submodule add -b $REMOTE_BRANCH $REMOTE_URL

#git checkout $LOCAL_BRANCH

