git-tx: git transplant -- maintain a tree composed of parts of other repositories

git-tx synchronizes a directory in one repository to a corresponding directory in another git repository. 
This supports composing projects from all or part of other projects.  
Unlike git submodules or 'fake' git submodules,  normal git commands in a git-tx tracked directory work 
as if there was no git-tx tracking.  Clones of the super-project are normal repos. 
Only the developers who need to update the tracking directories need to know about git transplant.
They use explicit git-tx commands to control cross-repo synchronization.  

git-tx works with two local repositories. In the destination repository, you issue 'git-tx clone' to 
copy a subdirectory from the other repository. As a side effect, git-tx stores information about the
HEAD commit in both repositories and the paths to the subdirectories. This information is stored in
a '.gittx' file in the destination subdirectory. Later, when either repository has changed, you 
can use git-tx-pull or git-tx-push to resynchronize the directories.


Subcommands


usage: git tx-clone [--name <projectName> ] [--branch <branchname>] [--prefix <LOCAL_PATH_PREFIX>] <remote_url> <remote_path> 

    Clone a remote repository subdirection into a local directory that does not yet exist.

    -n, --name ...        override default name for transplant branch
    -t, --branch ...      override 'master' default branch of remote
    -d, --prefix ...      override ./projectName/remote_path as directory path in local for transplant
    -v, --verbose         echo information
    -x, --verbose_only    echo information then exit
    
Clones the <url>, checks out the <branchname>,  and copies the directory <remote_path> into the <local_path> and commits the change. 

<projectName> defaults to the characters in the last segment of the URL, dropping the file extension. For example,  https://johnjbarton@github.com/johnjbarton/front-end.git results in 'front-end'. To transplant multiple directories from the same remote repo, use eg projectName/remotePath.

Creates a new git remote is defined at TX.<projectName> and a new ref refs/tx/TX.<projectName> pointing to HEAD before the transplant.

If the working tree is dirty or the <local_path> exists, the command fails.


git tx pull <projectName>

Merges remote changes into the directory tracking <projectName>.

Creates a new branch named tx.<projectName> starting at the tag tx.<projectName>. Fetches the remote corresponding to <projectName>. Merges the remote tracking into the <projectName> orphan branch.  Copies the <remote_path> specfied during 'git tx clone' onto the <local_path> specified during 'git tx clone'. Commits this patch, advancing tx.<projectName>. Attempts to merge branch tx.<projectName> into the current branch.   User must resolve any conflicts. 

If the working tree has any changes the command fails. If the orphan tree cannot be merged with its remote the command fails (how to recover in this case?)


git tx rebase <projectName>

As with git tx pull, but the last step is a rebase.


git tx push <projectName>

Push commits within the <local_path> back to the remote repo.

Create a new branch named tx.<projectName> starting at the tag tx.<projectName>. For each commit between tag tx.<projectName> and HEAD that changes the <local_path>,  chrerrypick the commit onto tx.<projectName>, reset HEAD^, copy the changed files onto the orphaned branch named <projectName>, and commit the change using the same commit info as the cherrypick.  Finally, push the orphaned branch to its remote.


git tx delete <projectName>

Cleans up any git-tx related meta-data in the repo.