#!/bin/sh

# git tx-clone [-name <projectName> ] [-t <branchname>]  -d <local_path> <url> <remote_path> 

export PATH=$PATH:`pwd`/bin

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

FROM_D=`pwd`
cd /tmp
echo "$PATH"

rm -r -f /tmp/git-tx

git clone git@github.com:johnjbarton/git-tx.git
cd git-tx


git tx-clone 
mustFail
git tx-clone git@github.com:johnjbarton/git-tx.git
mustFail
git tx-clone -x --prefix testTransplant git@github.com:johnjbarton/git-tx.git test
mustPass
git tx-clone --prefix testTransplant git@github.com:johnjbarton/git-tx.git test
mustPass

DELTA=`diff test testTransplant/test`
if  [ -z "$DELTA" ]; then
  echo "PASS"
else
  echo ">> FAIL <<"
  exit 11
fi

git tx-rm git-tx

cd ..
rm -r -f git-tx

cd "$FROM_D"

