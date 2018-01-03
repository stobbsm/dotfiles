#!/bin/bash
function error () {
	echo -e "\e[1;41;97mError occured:\e[0m$1"
	exit $2
}

function parse_cmd () {
	local cmdstring=$1
	local link=$2
	local file=$3
	local postcmd=`echo "${cmdstring}" | \
		sed "s@%d@$link@g" | \
		sed "s@%f@$file@g"`
	echo $postcmd
}

function get_hash () {
	local file=$1
	if [ ! -f $file ]
	then
		local hash=0
	else
		local hash="$(sha256sum $file | awk '{print $1}')"
	fi
	echo $hash
}

function hash_compare () {
	local file1=$1
	local file2=$2
	[[ `get_hash $file1` = `get_hash $file2` ]] && echo 0 || echo 1
}

function debug() {
	if [ ! -z "$DEBUG" ]
	then
		echo -e $(yellow [Debug message: $(normal $@)$(yellow ])) >&2
	fi
}

# functions for coloured text
function reset() {
	local txt="$@"
	echo "\e[0m${txt}"
}

function normal() {
	local txt="$@"
	reset ${txt}
}

function red() {
	local txt="$@"
	echo "\e[31m${txt}$(reset)"
}

function green() {
	local txt="$@"
	echo "\e[32m${txt}$(reset)"
}

function yellow() {
	local txt="$@"
	echo "\e[33m${txt}$(reset)"
}
