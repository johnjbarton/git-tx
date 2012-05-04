#!/bin/sh

# git tx-clone [-name <projectName> ] [-t <branchname>]  -d <local_path> <url> <remote_path> 

export PATH=$PATH:../bin

mustFail() {
  if [ $? -eq 1 ]; then
    echo "PASS"
  else
    echo ">> FAIL <<"
    exit 10
  fi
}
mustPass() {
  if [ $? -eq 0 ]; then
    echo "PASS"
  else
    echo ">> FAIL <<"
    exit 10
  fi
}

git tx-clone 
mustFail
git tx-clone git@github.com:johnjbarton/front-end.git
mustFail
git tx-clone -x --destination front-end/Images git@github.com:johnjbarton/front-end.git Images
mustPass
git tx-clone --destination front-end/Images git@github.com:johnjbarton/front-end.git Images
mustFail

