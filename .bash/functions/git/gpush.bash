gpush() {
    if ! _git_is_git_repo; then
    	return 1
    fi

	local commit_msg=""
    local OPTIND opt
    
    # Parse explicit arguments
    while getopts "m:" opt; do
        case "$opt" in
            m) commit_msg="$OPTARG" ;;
            *) echo "Usage: gpush [-m message]"; return 1 ;;
        esac
    done
    shift $((OPTIND-1))
    
    _git_resolve_conflict -u || return 1

	_git_review || return 1

    _git_commit "$commit_msg"
}
