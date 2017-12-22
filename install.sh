#!/bin/bash

if [ -f functions.sh ]
then
	. functions.sh
else
	echo "Error: File not found functions.sh"
	exit 2
fi

if [ -f errors.sh ]
then
	. errors.sh
else
	echo "File not found errors.sh" 2
fi

if [ ! -z $1 ]
then
	echo "Using $1 as pretend \$HOME"
	HOME=$1
	if [ ! -d $HOME ]
	then
		mkdir -pv $HOME
		debug "Created $HOME"
	fi
fi

base_dir="$(pwd)/base"
host_dir="$(pwd)/hostfiles/$(hostname)"
tmp_dir="/tmp/$(whoami)/$(hostname)"

# Load variables from settings and colours in base and host_dir if it exists
[[ -f "$base_dir/.settings" ]] && source $base_dir/.settings
[[ -f "$base_dir/.colours" ]] && source $base_dir/.colours
[[ -f "$base_dir/.applications" ]] && source $base_dir/.applications
[[ -f "$host_dir/.settings" ]] && source $host_dir/.settings
[[ -f "$host_dir/.colours" ]] && source $host_dir/.colours
[[ -f "$host_dir/.applications" ]] && source $host_dir/.applications

changed_files=0

if [ ! -d $tmp_dir ]
then
	mkdir -pv $tmp_dir
	debug "Created $tmp_dir"
fi

if [ ! -d "$base_dir" ]
then
	error "$base_dir doesn't exist" $EDIR
fi

# Load file map
[[ -f filemap.conf ]] && source filemap.conf || error "Can't load filemap" EFILE
debug "Loaded filemap.conf"

# Get files in base
file_list=${!file_map[@]}
debug "file_list $file_list"

# Filter files using the settings and colours provided
sed_options=""
for setting in $settings
do
	setting_content=${!setting}
	sed_options+="-e 's@{{$setting}}@$setting_content@g' "
done

for colour in $colours
do
	colour_code=${!colour}
	sed_options+="-e 's@{{$colour}}@$colour_code@g' "
done

for application in $applications
do
	application_content=${!application}
	sed_options+="-e 's@{{$application}}@$application_content@g' "
done
sed_cmd="sed -i $sed_options"
debug $sed_cmd

echo -e "Installing dotfiles..."
for file in $file_list
do
	link=${file_map[$file]}
	
	if [ -f $host_dir/$file ]
	then
		src=$host_dir/$file
	else
		src=$base_dir/$file
	fi
	debug "src => $src"

	if [ -f $src ]
	then
		if [ ! -z "${generate_map[$file]}" ]
		then
			touch $tmp_dir/$file
			echo -e "Generating $file"
			cat $src >> $tmp_dir/$file
			for cfile in ${generate_map[$file]}
			do
				if [ -f $base_dir/$cfile ]
				then
					echo -e "Found: $cfile"
					cat $base_dir/$cfile >> $tmp_dir/$file
					echo "" >> $tmp_dir/$file
				else

					echo -e "Can't find $cfile to add to $file, skipping"
				fi
			done
			src=$tmp_dir/$file
		fi
		
		if [ "$src" != "$tmp_dir/$file" ]
		then
			cp $src $tmp_dir/$file
			src=$tmp_dir/$file
		fi
		debug "src => $src"

		# Run the filter on the source file (which should be in tmp at this point)
		filter_cmd="$sed_cmd $src"
		debug "filter_cmd => $filter_cmd"
		eval $filter_cmd

		if [ "$(hash_compare $src $link)" = "1" ]
		then
			changed_files=$(( changed_files + 1 ))
			# Run pre commands if they exist
			if [ ! -z "${pre_commands[$file]}" ]
			then
				precmd=$(parse_cmd "${pre_commands[$file]}" "$link" "$file")
				eval $(echo $precmd) >/dev/null 2>&1
			fi

			echo -e "Installing $link"				
			install -D $src $link

			# Run post commands if they exist
			if [ ! -z "${post_commands[$file]}" ]
			then
				postcmd=$(parse_cmd "${post_commands[$file]}" "$link" "$basedir/$file")
				eval $(echo $postcmd) >/dev/null 2>&1
			fi
		fi
	else
		echo -e "Source file doesn't exist: $src"
	fi
done

echo -e "Modified $changed_files files"

echo -e "Checking for vim Plugged plugin manager..."

plugged_url="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
vim_plug_path="$HOME/.vim/autoload/plug.vim"
nvim_plug_path="$HOME/.local/share/nvim/site/autoload/plug.vim"

if [ ! -f $vim_plug_path ]
then
	echo -e "Installing for vim..."
	curl -fLo $vim_plug_path --create-dirs $plugged_url
else
	echo -e "Installed for vim"
fi

if [ ! -f $nvim_plug_path ]
then
	echo -e "Installing for nvim..."
	curl -fLo $nvim_plug_path --create-dirs $plugged_url
else
	echo -e "Installed for nvim"
fi

echo -e "Cleaning up..."
rm -rf $tmp_dir
debug "Removed $tmp_dir"
echo -e "If your .bashrc was updated, run source ~/.bashrc to enable the new one."
