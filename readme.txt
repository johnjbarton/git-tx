git-tx: git transplant -- maintain a tree composed of parts of other repositories

git-tx synchronizes a directory in one repository to a corresponding directory
in another git repository. This supports composing projects from all or part 
of other projects.  

Unlike git submodules or 'fake' git submodules:
  subdirectories can be tracked, 
  normal git commands in a git-tx tracked directory are normal
  clones of the super-project are normal repos, 
  Only the developers who need to update the tracking directories 
    need to know about git transplant. They use explicit git-tx 
    commands to control cross-repo synchronization.  

On the other hand, unlike git submodules or 'fake' git submodules, 
  transplants sync by patches across trees rather than commits on full trees.
  push/pull works from a local reference copy outside the tree

git-tx works with two local repositories. 
  1) "Other", or "graft-source" repository,
  2) "Destination" or "transplant" repository.
In the destination repository, you issue 'git-tx clone' to copy a 
subdirectory from the other repository.  As a side effect, git-tx stores 
information in the destination repo. The information includes the HEAD 
commit in both repositories and the paths to the subdirectories. This 
information is stored in a '.git-tx' director in the destination 
tree and is committed along with the transplant. 

Later, when either repository has changed, you can use git-tx-pull 
or git-tx-push to resynchronize the directories and the info in the .git-tx
directory will be consulted.

Examples:

Suppose you have two repositiories, /work/a and /work/b, and you want b to 
track a/lib:

  cd /work/b
  git tx-clone /work/a/lib
  git push
  
The result will be a subdirectory /work/b/a/lib and two commits to b, one for
the tracked subdirectory and one for /work/b/.git-tx metadata.

Now suppose your colleagues clone your repo 'b'. They will see a new directory
under /a/lib. They can use and even update that directory.

Later you learn that 'a' has updates:
  cd /work/a
  git pull
  cd /work/b
  git tx-pull a
This will cause just the changes from a/lib to be patched onto /work/b/a/lib
and the committed.

Next suppose you want to submit a pull request to project 'a' based on your
teams changes to b/a/lib:
  cd /work/b
  git pull
  git tx-push a
  cd /work/a
  git reset HEAD^   # dump the changeset from 'a' back into the workset
  git branch pullBranch
  git commit -a -m "Team b has great stuff for Team a"
  git push 
  
Finally, suppose another team member wants to update project 'b' from changes in 'a'.
They will probably not have the same directory set up as you do, so they need to
clone 'a' and pass the new path to --other:
  cd /fun
  git clone <project 'a' url>
  cd /fun/b
  git pull --other /fun/a a

How git-tx works:

git-tx-clone --name <proj> --prefix <local_prefix> <other path>
   creates a new branch on this tree called tx-pull-<proj>
   creates a new branch on other tree called tx-pull-<proj> 
   copies the <other path> directory from the 'other' tree to this <local_prefix>
       in thistree.
   records the source and target commits in this tree ./.git-tx/<proj>/

git-tx-push <proj>
   computes the diff between the current feature branch and tx-pull-<proj>, within
     the transplanted subdirectory
   creates a new branch on other tree called tx-<proj>-<feature> starting at 
      tx-pull-<proj>
   applies the patch to this new branch
   dev is takes over to test, merge, and commit 
   


Note:
  The transplant tree must have no outstanding changes (commit or stash them). 
  Always use git tx-pull before git tx-push if the other tree has moved forward.
These two conditions help avoid merge conflicts across trees. Merge conflicts 
within each tree are handled as normal git conflicts.

Subcommands

usage: git tx-clone [--name <projectName> ] [--branch <branchname>] [--prefix <LOCAL_PATH_PREFIX>] <other_path> 

 Copy and track another local repository subdirectory into this directory in this repository.

n,name=              override default name for transplant branch
p,prefix=             override default <project-name>/<other_prefix> for local path prefix
t,branch=            override 'master' default branch of other
x,explain            echo information then exit   

If the working tree is dirty or the <local_path> exists, the command fails.


git tx-pull <projectName>

  Merges changes into the directory tracking <projectName>.

o,other=             set <path> as source of transplant        
v,verbose            echo information
x,verbose_only       echo information then exit

If the working tree has any changes the command fails. 


git tx-push <projectName>

Push changes within the <local_path> back to the other repo.

o,other=             set <path> as source of transplant 
v,verbose            echo information
x,verbose_only       echo information then exit

git tx-rm <projectName>

Cleans up any git-tx related meta-data in the repo.
