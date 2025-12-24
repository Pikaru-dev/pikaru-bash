gmerge() {
    _git_is_git_repo || return 1

	echo "Select source branch to pull from:"
    local src=$(_git_select_branch)
    [[ -z "$src" ]] && return 1

	echo "Select a destination branch to push into:"
    local dest=$(_git_select_branch)
    [[ -z "$dest" ]] && return 1

    _git_checkout_versatile "$dest" || return 1

    echo "Merging '$src' into '$dest'..."
    
    if ! git merge "$src"; then
        _git_resolve_conflict -u || return 1
    else
        git reset > /dev/null
    fi

    _git_review || return 1

    _git_commit
}
