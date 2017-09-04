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
	error "File not found errors.sh" 2
fi

if [ ! -z $1 ]
then
	echo "Using $1 as pretend \$HOME"
	HOME=$1
	if [ ! -d $HOME ]
	then
		mkdir -pv $HOME
	fi
fi

base_dir="$(pwd)/base"
host_dir="$(pwd)/hostfiles/$(hostname)"
tmp_dir="/tmp/$(whoami)/$(hostname)"

changed_files=0

if [ ! -d $tmp_dir ]
then
	mkdir -pv $tmp_dir
fi

if [ ! -d "$base_dir" ]
then
	error "$base_dir doesn't exist" $EDIR
fi

# Load file map
source filemap.conf

# Get files in base
file_list=${!file_map[@]}

echo -e "Installing dotfiles..."
for file in $file_list
do
	link=${file_map[$file]}
	
	if [ -z "${host_file_map[$file]}" ]
	then
		src=$base_dir/$file
	else
		if [ -f $host_dir/$file ]
		then
			src=$host_dir/$file
		else
			src=$base_dir/$file
		fi
	fi

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

		if [ "$(hash_compare $src $link)" = "1" ]
		then
			changed_files=$(( changed_files + 1 ))
			# Run pre commands if they exist
			if [ ! -z "${pre_commands[$file]}" ]
			then
				precmd=$(parse_cmd "${pre_commands[$file]}" "$link" "$file")
				eval $(echo $precmd) >/dev/null 2>&1
			fi
				
			install -D $src $link

			# Run post commands if they exist
			if [ ! -z "${post_commands[$file]}" ]
			then
				postcmd=$(parse_cmd "${post_commands[$file]}" "$link" "$basedir/$file")
				eval $(echo $postcmd) >/dev/null 2>&1
			fi
		else
			echo -e "Files hasn't changed, not copying."
		fi
	else
		echo -e "Source file doesn't exist: $src"
	fi
done

echo -e "Modified $changed_files files"

echo -e "Cleaning up..."
rm -rf $tmp_dir
