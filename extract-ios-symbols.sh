#!/bin/bash
# iOS Symbol 추출 자동화 스크립트
# Last modified: 2021.10.12
#

set -xe
if [ $# -lt 3 ];
then
    echo "USAGE: $0 {arm64_ipsw_file_name} {arm64e_ipsw_file_name} {os_version (build_name)}"
    exit 1
fi

# Variables
BASE_DIR=$(pwd)
arm64=$1
arm64e=$2
target=$3

function rm_dir() {

  FOLDER_LIST=$(find $BASE_DIR -mindepth 1 -maxdepth 1 -type d | grep -v "Symbols")
  for folder in "${FOLDER_LIST[@]}"; do
    rm -rf $folder
  done
}

function extract_arm64() {

	ipsw extract -d $arm64
	valid_cache=$(ls -d */ | grep -v "Symbols"| awk '{print $1}')
	dsc_extractor $valid_cache/dyld_shared_cache_arm64 $BASE_DIR/Symbols_64

	rm_dir
}

function extract_arm64e() {

	ipsw extract -d $arm64e
	valid_cache=$(ls -d */ | grep -v "Symbols"| awk '{print $1}')
	dsc_extractor $valid_cache/dyld_shared_cache_arm64e $BASE_DIR/Symbols_64e

	rm_dir
}

function tar_symbols() {

	mkdir -p $BASE_DIR/"`echo $target`"
	mv $BASE_DIR/Symbols $BASE_DIR/"`echo $target`"
	tar czf "`echo $target`.tar.gz" "`echo $target`"
	
	tar_size=$(du -s "`echo $target`.tar.gz" | awk '{print $1}')
	echo "target_size: $tar_size"
}



extract_arm64
sleep 5s
extract_arm64e
merge_symbols.sh $BASE_DIR/Symbols_64e $BASE_DIR/Symbols_64

mv $BASE_DIR/Symbols_64e $BASE_DIR/Symbols
tar_symbols

exec python -m http.server
