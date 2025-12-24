_meta_browse_dir () {
	local original_dir=$(pwd)
    local current_dir
    local selected

    local new_option="--NEW"

    if [ -z "$1" ] || [ ! -d $1 ]; then
    	current_dir="$original_dir"
    else
    	current_dir="$1"
    fi

    cd "$current_dir" || return 1

    while true; do
        selected=$( (ls -pa; echo "$new_option") | fzf --height 40% --reverse --header "Current: $PWD")

        if [[ "$selected" == "$new_option" ]]; then
        	read -p "Enter new file name: " file_name
        	if [[ -n "$file_name" ]]; then
				touch "$file_name"
				selected="$file_name"
        	else
				selected=""
        	fi
        fi

		# eval
		if [[ -z "$selected" ]]; then
			cd "$original_dir"
			break
        fi

        if [[ "$selected" == */ ]]; then
            cd "$selected" || continue
        else
            echo "$PWD/$selected"
            cd "$original_dir"
            break
        fi
    done

    return 0
}
