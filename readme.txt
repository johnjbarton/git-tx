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
  push/pull works operates on a local reference copy outside the tree

git-tx works with two local repositories. 
  1) "Other", or "graft-source" repository,
  2) "Local", "Destination" or "transplant" repository.
In the local or destination repository, you issue 'git-tx clone' to copy a 
subdirectory from the 'other' repository.  

As a side effect, git-tx stores information in the destination repo. The 
information includes both branches used (local and other) during the copy,
the HEAD commit in both repositories and the paths to the subdirectories. This 
information is stored in a '.git-tx' director in the destination 
tree and is committed along with the transplant. 

Later, when either repository has changed, you can use git-tx-pull 
or git-tx-push to resynchronize the directories and the info in the .git-tx
directory will be consulted.

To bring updates from 'other' into 'local', use git-tx-pull. This will switch
both trees to the branches used git-tx-clone, then copy the files in the
other tree under the specific subdirectory onto the local tree. The changes
are committed to the local tree then merged in to the current branch.

To update the other tree with changes from the local one, use git-tx-push. 
The other tree is switched to the git-tx-clone branch and the files under the
local subdirectory are copied to the other tree. Use this with a local feature
branch to create a patch on the other tree. 

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
       in this tree.
   records the source and target commits in this tree ./.git-tx/<proj>/

The other tree looks like: 

   other_commit
   |
   \/
   A  Other_branch
   ^
   | 
   tx-pull-<proj>
   
The local tree looks like:

   local_commit
   |
   \/
   Z <---M  Local_branch
   ^                    
   |               
   tx-pull-<proj>

Where M is the meta-data commit

git-tx-pull <proj>
   
After git-tx-clone, Other_branch may grow with new commits B,C,D:

   other_commit
   |
   \/
   A <--- B <---- C <----D Other_branch
   ^
   | 
   tx-pull-<proj>

Local_branch may grow with Y, X, W, and a feature branch to V

   local_commit
   |
   \/
   Z <--- M <---- X <----W Local_branch  
   ^              \      
   |               \
   tx-pull-<proj>   -V feature_branch
   
The git-tx-pull rebases the tx-pull-<proj> branch on the other tree:

   other_commit
   |
   \/
   A <--- B <---- C <----D Other_branch
                         ^
                         | 
                         tx-pull-<proj>

then computes the diff within the subdirectory between the other commit and 
HEAD, and applies the patch to local:

   local_commit
   |
   \/
   Z <--- M <---- X <----W Local_branch        
   |               \
   \                \
    D'               -V feature_branch
    ^
    |
    tx-pull-<proj>  

This much is done by git-tx-fetch. git-tx-pull then merges the result back 
into local branch:

   local_commit
   |
   \/
   Z <--- M <---- X <----W <---- D" Local_branch        
                   \             ^
                    \            tx-pull-<proj>
                     -V feature_branch
     
and finally the commit markers on both trees are move forward.

                                 local_commit
                                 |
                                 \/
    Z <---M <---- X <----W <---- D" <---- N Local_branch        
                   \             ^
                    \            tx-pull-<proj>
                     -V feature_branch

Here N is the new meta-data commit.

The developer must rebase or merge the feature branch to obtain
the updates as normal.

git-tx-push
  
Before tx-push will start, the tx-pull-<proj> branch must be at head:

                         other_commit
                         |
                         \/
   A <--- B <---- C <----D Other_branch
                         ^
                         | 
                         tx-pull-<proj>

Similarly the local copy must be up to date, meaning that the 
current branch on local to be pushed must be ahead of local_commit.

                                local_commit
                                |
                                \/
   Z <--- M <---- X <----W <---- D" <----N Local_branch        
                                 ^\
                                 | \
                                 |  V' <----U feature
                                 tx-pull-<proj>
                     
When we use git-tx-push on the feature branch, we compute the diff
within the subdirectory between the tx-pull-<proj> and feature,
and apply it to a new branch on the other tree:

                         other_commit
                         |
                         \/
   A <--- B <---- C <----D  Other_branch
                         ^\
                         | \---U'  tx-<proj>-feature
                         | 
                         tx-pull-<proj>

At this point the developer can test, merge with the other branch, or 
other actions.  If the local feature branch advances:

                                local_commit
                                |
                                \/
   Z <--- Y <---- X <----W <---- D" <----N Local_branch        
                                 ^\
                                 | \
                                 |  V' <----U <----S feature
                                 tx-pull-<proj>

a second tx-push will extend the branch in the other tree:

                         other_commit
                         |
                         \/
   A <--- B <---- C <----D  Other_branch
                         ^\
                         | \---U' <----S'  tx-<proj>-feature
                         | 
                         tx-pull-<proj>

For this reason the diffs we use are really "copy over changed
files and let git compute diffs on commit".

git-tx-pull redux

Now that we have used tx-push, consider a tx-pull:

                         other_commit
                         |
                         \/
   A <--- B <---- C <----D <---- E  Other_branch
                         ^\
                         | \---U' <----S'  tx-<proj>-feature
                         | 
                         tx-pull-<proj>

The tx-pull will rebase the base tx-pull-proj branch and
any feature branches:


                                 other_commit
                                 |
                                 \/
   A <--- B <---- C <----D <---- E  Other_branch
                                 ^\
                                 | \---U' <----S'  tx-<proj>-feature
                                 | 
                                 tx-pull-<proj>

The patch applied to the local tree:

                                                local_commit
                                                |
                                                \/
   Z <--- Y <---- X <----W <---- D" <----N <--- E" Local_branch        
                                  \             ^
                                   \            |
                                    \           tx-pull-<proj>
                                     \
                                      V' <----U <----S feature
                                 
will leave the feature branch out of sync with the other tree. The
developer is advised to merge or rebase the feature branch to the
local_branch.


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
