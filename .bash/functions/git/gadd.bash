gadd() {
	if ! _git_is_git_repo; then
		return 1
	fi

    local new_branch_name=$1    
    local priority_branches=("main" "master" "develop")
    local base_branch=""
    
    if [ -z "$new_branch_name" ]; then
        read -p "Enter new branch name: " new_branch_name
    fi

    if [ -z "$new_branch_name" ]; then
    	return 1
    fi

    if ! _git_is_git_repo; then
        return 1
    fi

    for branch in "${priority_branches[@]}"; do
        if git show-ref --verify --quiet "refs/heads/$branch"; then
            echo "Found local priority branch: $branch"            
            git checkout "$branch" || return 1
            base_branch=$branch
            break
        elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
            echo "Found remote priority branch: origin/$branch"
            echo "Creating local tracking branch..."
            git checkout --track "origin/$branch" || return 1
            base_branch=$branch
            break
        fi
    done

    if [[ -z "$base_branch" ]]; then
        base_branch=$(_git_current_branch)
        echo "No priority base found. Using current branch: $base_branch"
    fi

    echo "Updating base branch '$base_branch'..."
    if ! git pull; then
        echo "[ERROR] Failed to update (pull) '$base_branch'. Aborting to prevent conflicts."
        echo "        Please resolve the issue with the base branch manually."
        return 1
    fi

    echo "Creating '$new_branch_name' from '$base_branch'..."
    if git checkout -b "$new_branch_name"; then
        echo "Branch created successfully."
        
        echo "Pushing to origin..."
        if git push -u origin "$new_branch_name"; then
            echo "[OK] '$new_branch_name' is live on remote."
        else
            echo "[WARNING] Branch created locally, but failed to push to remote."
            return 1
        fi
    else
        echo "[ERROR] Failed to create branch. It may already exist."
        return 1
    fi
}
