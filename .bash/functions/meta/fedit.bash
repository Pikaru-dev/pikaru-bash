fedit () {
	edit_file=$(_meta_browse_dir "$HOME/.bash/functions")

	if [ -z "$edit_file" ]; then
		return 0
	else
		micro "$edit_file"
	fi

    reload
}
