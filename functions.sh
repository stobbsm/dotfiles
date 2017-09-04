#!/bin/bash
function error () {
	echo "Error occured: $1"
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
	local hash="$(sha256sum $file | awk '{print $1}')"
	echo $hash
}

function hash_compare () {
	local file1=$1
	local file2=$2
	[[ `get_hash $file1` = `get_hash $file2` ]] && echo 0 || echo 1
}
