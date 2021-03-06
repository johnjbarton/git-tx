#!/bin/sh

# git tx-clone [-x] [-name <projectName> ] [-t <branchname>] <other_path> 

export PATH=$PATH:`pwd`/bin

mustFail() {
  RC=$?
  if [ $RC -ne 0 ]; then
    echo "PASS"
  else
    echo ">> MUST FAIL $RC <<"
    exit $RC
  fi
}
mustPass() {
  RC=$?
  if [ $RC -eq 0 ]; then
    echo "test --------------------------------------------------> PASS"
  else
    echo "test -------------------------------------------------->> FAIL: $RC <<"
    exit $RC
  fi
}
checkBranches() {
  LOCAL_BRANCH=`git symbolic-ref HEAD | sed -e 's/^.*\///'`
  if [ "$LOCAL_BRANCH" != "master" ]; then 
    echo ">>>>>>>>>>>>> FAIL:  Local not on master, on $LOCAL_BRANCH"
    exit 22
  fi
  cd /tmp/git-tx-right
  OTHER_BRANCH=`git symbolic-ref HEAD | sed -e 's/^.*\///'`
  if [ "$OTHER_BRANCH" != "master" ]; then 
    echo ">>>>>>>>>>>>> FAIL:  Other not on master, on $OTHER_BRANCH"
    exit 23
  fi
  cd /tmp/git-tx-left
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

echo "test -------------------------------------------------->  normal, with --prefix"
git tx-clone --prefix git-tx/prefix/test /tmp/git-tx-right/test
mustPass

checkBranches

echo "test -------------------------------------------------->  correct copy"
DELTA=`diff /tmp/git-tx-left/git-tx/prefix/test /tmp/git-tx-right/test`
if  [ -z "$DELTA" ]; then
  echo "PASS"
else
  echo ">>>>>>>>>>>>> FAIL:  $DELTA"
  exit 11
fi

echo "test -------------------------------------------------->  directory exists"
git tx-clone /tmp/git-tx-right
mustFail

if [ -z "$( cat /tmp/git-tx-left/.git-tx/git-tx/local_prefix)" ]; then
  echo ">>>>>>>>>>>>> FAIL:  Local prefix blank"
  exit 19
fi

rm -r -f /tmp/git-tx-save
mv /tmp/git-tx-right /tmp/git-tx-save
rm -r -f /tmp/git-tx-other
cd /tmp
git clone git@github.com:johnjbarton/git-tx.git git-tx-other
cd /tmp/git-tx-left

echo "test -------------------------------------------------->  tx-pull missing --other"

git tx-pull git-tx
mustFail

echo "test -------------------------------------------------->  tx-pull --other"
cd /tmp/git-tx-left
git checkout master
git tx-pull --other /tmp/git-tx-other git-tx
mustPass

mv /tmp/git-tx-save /tmp/git-tx-right
git tx-pull --other /tmp/git-tx-right git-tx
mustPass

checkBranches
echo "test --------------------------------------------------> git-tx-push -x "
TX_PUSH_TEST="git-tx/prefix/test/pushme.txt"
echo "this is a test on $( date )" >> "$TX_PUSH_TEST"
git add "$TX_PUSH_TEST"
git commit -m "test git-tx-push"

git tx-push -x git-tx
mustPass

echo "test --------------------------------------------------> git-tx-push "
git tx-push git-tx
echo "tx-push ends in $( pwd )"
mustPass

if [ ! -r /tmp/git-tx-right/test/pushme.txt ]; then
  echo "git-tx-push failed to create pushme.txt"
  exit 35
fi

echo "Simulate developer merge"
cd /tmp/git-tx-right
git reset master
git checkout master
git add -A
git commit -m "simulate developer reset and re-commit from tx-push "

if [ "$( diff /tmp/git-tx-left/"$TX_PUSH_TEST" /tmp/git-tx-right/test/pushme.txt )" ]; then
  echo ">>>>>>>>>>>>> FAIL:  git-tx-push: files not identical"
  exit 15
fi

checkBranches

echo "test -------------------------------------------------->  tx-pull -x"
cd /tmp/git-tx-right
echo "this is a test on $( date )" >> test/pullme.txt
git add test/pullme.txt
git commit -m "test git-tx-pull"
cd /tmp/git-tx-left

git tx-pull -x git-tx

echo "test -------------------------------------------------->  tx-pull "
git tx-pull git-tx
mustPass

if [ ! -e /tmp/git-tx-left/git-tx/prefix/test/pullme.txt ]; then
  echo ">>>>>>>>>>>>> FAIL:  23 no /tmp/git-tx-left/git-tx/prefix/test/pullme.txt"
  exit 23
fi

if [ $( diff /tmp/git-tx-left/git-tx/prefix/test/pullme.txt /tmp/git-tx-right/test/pullme.txt ) ]; then
  echo ">>>>>>>>>>>>> FAIL:  16 git-tx-pull: files not identical"
  exit 16
fi

EXTRA_FILES="$(find /tmp/git-tx-left/ -name pullme.txt | wc -l)"
if [ "$EXTRA_FILES" -ne "1" ]; then
  echo ">>>>>>>>>>>>> FAIL:24, $EXTRA_FILES extra files"
  find /tmp/git-tx-left/ -name pullme.txt
fi

OTHER_HEAD_SHA=$(cd /tmp/git-tx-right && git rev-parse HEAD && cd /tmp/git-tx-left)
if [ "$OTHER_HEAD_SHA" != $( cat /tmp/git-tx-left/.git-tx/git-tx/other_commit ) ]; then
  echo ">>>>>>>>>>>>> FAIL:  git-tx-push: other commit fails to record other head"
  exit 17
fi

checkBranches


echo ---------------- test git-tx-rm -----------------------

echo "test -------------------------------------------------->  tx-rm"
git tx-rm git-tx
mustPass

echo "test -------------------------------------------------->  directory clean up"
LEFT_OVER_REFS=$(find /tmp/git-tx-left/.git | grep refs/tx/git-tx )
if [ -z "$LEFT_OVER_REFS" ]; then
  echo "PASS"
else
  echo ">>>>>>>>>>>>> FAIL:  LEFT_OVER_REFS=\"$LEFT_OVER_REFS\""
  exit 12
fi

echo "TODO test override default project name"
echo "TODO test override default other-path branch"

cd "$FROM_D"

