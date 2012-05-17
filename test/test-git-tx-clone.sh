#!/bin/sh

# git tx-clone [-x] [-name <projectName> ] [-t <branchname>] <other_path> 

export PATH=$PATH:`pwd`/bin

mustFail() {
  if [ $? -eq 1 ]; then
    echo "PASS"
  else
    echo ">> FAIL <<"
    exit 10
  fi
  beClean
}
mustPass() {
  if [ $? -eq 0 ]; then
    echo "PASS"
  else
    echo ">> FAIL <<"
    exit 10
  fi
  beClean
}
beClean() {
  if [ `pwd` != "/tmp/git-tx-left" ]; then
    echo ">> FAIL << Did not return to /tmp/git-tx-left, still in `pwd` "
    exit 13
  fi
}

# set up for testing

FROM_D=`pwd`
cd /tmp
rm -r -f /tmp/git-tx-left
rm -r -f /tmp/git-tx-right
mkdir -p /tmp/notAGitDir
git clone git@github.com:johnjbarton/git-tx.git git-tx-left
git clone git@github.com:johnjbarton/git-tx.git git-tx-right
cd git-tx-left

echo ---------------- test git-tx-clone -----------------------

echo "test -------------------------------------------------->  no path given"
git tx-clone 
mustFail

echo "test -------------------------------------------------->  self clone" 
git tx-clone /tmp/git-tx-left
mustFail

echo "test -------------------------------------------------->  not a git directory "
git tx-clone /tmp/notAGitDir
mustFail

echo "test -------------------------------------------------->  -x explain `pwd`"
git tx-clone -x /tmp/git-tx-right/test
mustPass

echo "test -------------------------------------------------->  normal usage"
git tx-clone /tmp/git-tx-right/test
mustPass

echo "test -------------------------------------------------->  correct copy"
DELTA=`diff /tmp/git-tx-left/git-tx/test /tmp/git-tx-right/test`
if  [ -z "$DELTA" ]; then
  echo "PASS"
else
  echo ">> FAIL << $DELTA"
  exit 11
fi

echo "test -------------------------------------------------->  directory exists"
git tx-clone /tmp/git-tx-right
mustFail


echo "this is a test on $( date )" >> test/pushme.txt
git add test/pushme.txt
git commit -m "test git-tx-push"

echo ---------------- test git-tx-push -x -----------------------
git tx-push -x git-tx
mustPass

echo ---------------- test git-tx-push -----------------------
git tx-push git-tx
mustPass

if [ $( diff /tmp/git-tx-left/test/pushme.txt /tmp/git-tx-right/test/pushme.txt ) ]; then
  echo ">> FAIL << git-tx-push: files not identical"
  exit 15
fi

OTHER_HEAD_SHA=$(cd /tmp/git-tx-right && git rev-parse HEAD && cd /tmp/git-tx-left)
if [ "$OTHER_HEAD_SHA" != $( cat /tmp/git-tx-left/.git-tx/git-tx/other_commit ) ]; then
  echo ">> FAIL << git-tx-push: other commit fails to record other head"
  exit 17
fi

echo ---------------- test git-tx-pull -----------------------
cd /tmp/git-tx-right
echo "this is a test on $( date )" >> test/pullme.txt
git add test/pullme.txt
git commit -m "test git-tx-pull"
cd /tmp/git-tx-left

echo "test -------------------------------------------------->  tx-pull"
git tx-pull git-tx
mustPass

if [ $( diff /tmp/git-tx-left/test/pullme.txt /tmp/git-tx-right/test/pullme.txt ) ]; then
  echo ">> FAIL << git-tx-pull: files not identical"
  exit 16
fi

echo "test -------------------------------------------------->  tx-pull --other"

rm -r -f /tmp/git-tx-right

git tx-pull git-tx
mustFail
set -x -v
git tx-pull --other /tmp/git-tx/right git-tx
mustPass
exit 1
echo ---------------- test git-tx-rm -----------------------

echo "test -------------------------------------------------->  tx-rm"
git tx-rm git-tx
mustPass

echo "test -------------------------------------------------->  directory clean up"
LEFT_OVER_REFS=$(find /tmp/git-tx-left/.git | grep refs/tx/git-tx )
if [ -z "$LEFT_OVER_REFS" ]; then
  echo "PASS"
else
  echo ">> FAIL << LEFT_OVER_REFS=\"$LEFT_OVER_REFS\""
  exit 12
fi

echo "TODO test override default project name"
echo "TODO test override default other-path branch"

cd "$FROM_D"

