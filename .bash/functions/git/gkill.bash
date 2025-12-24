gkill () {
	if ! _git_is_git_repo; then
		return 1
	fi

	local current_branch=$(_git_current_branch)
	local branch_name

	if [ -z "$1" ]; then
		branch_name=$(_git_select_branch)
	else
		branch_name="$1"
	fi

	if [ "$branch_name" == "$current_branch" ]; then
		echo "Error: Cannot delete current branch."
		return 1
	fi

	git push origin -d "$branch_name";
	git branch -d "$branch_name";
	git fetch origin -p;
}
