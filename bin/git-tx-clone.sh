#!/bin/sh

# git tx-clone [--name <projectName> ] <url> <branchname>  <remote_path> <local_path>

# Clones the <url>, checks out the <branchname>,  and copies the directory <remote_path> into the <local_path> and commits the change. 

#<projectName> defaults to the characters in the last segment of the URL, dropping the file extension. 
# For example,  https://johnjbarton@github.com/johnjbarton/front-end.git results in 'front-end'. To transplant multiple directories from the same remote repo, use eg projectName/remotePath.

#The cloned remote repo is placed on an empty orphaned branch name <projectName>.  Creates a commit as if you issued  git add <local_path> then git commit -m 'git tx clone <url> <branchname>  <remote_path> <local_path>' . Also adds a new remote reference named by the project and pointing to <url> and tags HEAD with the name 'tx.<projectName>'.

# If the <local_path> exists, the command fails.