#!/bin/sh
set -e -v

# Setup a test repo
git clone git@github.com:johnjbarton/atopwi.git
cd atopwi

# git tx-clone [--name <projectName> ] <url> <branchname>  <remote_path> <local_path>

# Must be unique
#
PROJECT_NAME="front-end"

REMOTE_URL="git@github.com:johnjbarton/front-end.git"

# Must not be blank, default to 'master'
REMOTE_BRANCH="protocolExtension"

# relative to the current working directory...in the *local* tree!
# so we must be at root of the local tree
#
REMOTE_PATH=""

# Path prefix must end in "/" 
LOCAL_PATH="inspector/front-end/"

# Strip refs/head/<branch> to give <branch>
#
LOCAL_BRANCH=`git symbolic-ref HEAD | sed -e 's/^.*\///'`

# Fetch only one branch into our specially named remote
#
git remote add -f -t $REMOTE_BRANCH tx.$PROJECT_NAME $REMOTE_URL

# move the remote subtree into our local tree
#
git archive --format=tar --prefix=$LOCAL_PATH refs/remotes/tx.$PROJECT_NAME/$REMOTE_BRANCH $REMOTE_PATH | tar xf -
