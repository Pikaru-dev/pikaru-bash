_git_is_git_repo () {
	if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
	    echo "Error: Not a git repository."
	    return 1
	fi

	return 0
}

_git_current_branch () {
	_git_is_git_repo || return 1

	local current_branch=$(git branch --show-current)
	echo "$current_branch"
	return 0
}

_git_checkout_versatile () {
	_git_is_git_repo || return 1

    local target=$1

    [[ -z "$target" ]] && return 0

    if git show-ref --verify --quiet "refs/heads/$target"; then
        echo "Checking out local branch: $target"
        git checkout "$target"
        return $?
    fi

    local remote_branch="origin/$target"
    
    if git show-ref --verify --quiet "refs/remotes/$remote_branch"; then
        echo "Creating local tracking branch for: $remote_branch"
        git checkout --track "$remote_branch"
        return $?
    fi

    echo "Error: Branch '$target' not found locally or on 'origin'."
    return 1
}

_git_select_branch () {
	_git_is_git_repo || return 1

	selected_branch=$(
	    {
	        git branch --format='%(refname:short)' | awk '{print "L " $0}'
	        git branch -r --format='%(refname:short)' | grep -v 'HEAD' | awk '{print "R " $0}'
	    } | awk '
	        /^L/ { 
	            name = substr($0, 3)
	            seen[name] = 1
	            print name
	        }
	        /^R/ { 
	            full = substr($0, 3)
	            clean_name = full
	            sub(/^[^\/]+\//, "", clean_name)
	            if (!seen[clean_name]) {
	                print full
	            }
	        }
	    ' | fzf --height 40% --reverse --header "Select Git Branch (Locals + Untracked Remotes)"
	)

	if [ -z "$selected_branch" ]; then
		return 1
	else
		echo "$selected_branch"
	fi
}

_git_resolve_conflict() {
    _git_is_git_repo || return 1
    
    local unstage_after=false
    if [[ "$1" == "-u" || "$1" == "--unstage" ]]; then
        unstage_after=true
    fi

    echo "Checking for updates/merges..."
    if [[ -z $(git diff --name-only --diff-filter=U) ]]; then
        if git pull --no-rebase; then
            return 0
        fi
    fi

    echo -e "\n[!] Conflicts detected. Entering resolution mode..."

    while [[ -n $(git diff --name-only --diff-filter=U) ]]; do
        file=$(git diff --name-only --diff-filter=U | fzf \
            --header "Enter: Edit Conflict | esc: Abort" \
            --preview "git diff --color=always {}" \
            --preview-window='right:60%:wrap')

        [[ -z "$file" ]] && return 1

        ${EDITOR:-micro} "$file"

        if ! grep -qE '^<<<<<<<|^=======|^>>>>>>>' "$file"; then
            git add "$file"
        else
            echo "Warning: Markers still present in $file."
        fi
    done

    if [[ "$unstage_after" == true ]]; then
        echo "Resolutions complete. Unstaging for review..."
        git reset > /dev/null
    fi

    echo "All conflicts resolved."
    return 0
}

_git_commit() {
    _git_is_git_repo || return 1

    local msg="$1"

    if [[ -n $(git diff --cached --name-only) ]]; then
        echo -e "\n--- Reviewing Staged Changes ---"
        git diff --cached --stat
        
        if [[ -z "$msg" ]]; then
            read -r -p "Commit message (empty to abort): " msg
        fi

        if [[ -n "$msg" ]]; then
            if git commit -m "$msg"; then
                echo "Pushing to remote..."
                git push
            else
                echo "[!] Commit failed."
                return 1
            fi
        else
            echo "Action aborted: No commit message provided."
            return 1
        fi
    else
        echo "No changes staged. Nothing to commit."
        return 0
    fi
}

_git_review() {
    _git_is_git_repo || return 1

    if ! git rev-parse --verify @{u} >/dev/null 2>&1; then
        echo "Error: No upstream branch configured. Cannot perform explicit remote review."
        echo "Please set an upstream (e.g., git push -u origin $(_git_current_branch)) before proceeding."
        return 1
    fi

    while [[ -n $(git ls-files --others --exclude-standard; git diff --name-only) ]]; do
        out=$( (git ls-files --others --exclude-standard; git diff --name-only) | sort -u | fzf \
            --header "ctrl-s: Stage | ctrl-e: Edit | ctrl-d: Discard | esc: Finish" \
            --expect=ctrl-s,ctrl-d,ctrl-e \
            --preview="if git ls-files --error-unmatch {} >/dev/null 2>&1; then 
                          git diff @{u}...HEAD --color=always -- {}
                        else 
                          bat --color=always --style=numbers {} 2>/dev/null || cat {}
                        fi" \
            --preview-window='right:60%:wrap')
        
        key=$(head -1 <<< "$out")
        file=$(tail -1 <<< "$out")

        [[ -z "$key" ]] && break

        case "$key" in
            ctrl-s)
                [[ -n "$file" ]] && git add "$file"
                ;;
            ctrl-e)
                [[ -n "$file" ]] && ${EDITOR:-micro} "$file"
                ;;
            ctrl-d)
                [[ -z "$file" ]] && continue
                if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
                    read -p "Discard changes in $file? (y/n): " confirm
                    [[ $confirm == [yY] ]] && git checkout -- "$file"
                else
                    read -p "Delete untracked file $file? (y/n): " confirm
                    [[ $confirm == [yY] ]] && rm "$file"
                fi
                ;;
        esac
    done

    return 0
}
