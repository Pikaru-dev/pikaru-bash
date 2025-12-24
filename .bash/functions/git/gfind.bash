gfind() {
    if ! _git_is_git_repo; then
    	return 1
    fi

    local selected_branch

    if [ -z "$1" ]; then
		selected_branch=$(_git_select_branch)
    else
		selected_branch="$1"
    fi

    _git_checkout_versatile "$selected_branch"
}
