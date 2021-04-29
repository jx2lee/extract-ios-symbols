#!/bin/bash
# TechOps iOS Symbol 추출 자동화 스크립트
# Last modified: 2021.04.29
#
# script 순서
# 1. arm64 Architecture symbol 추출(ipsw)
# 2. codesign 명령어로 page size 확인
# 3. symbol file 추출 (dsc_extractor_4k)
# 4. fat binary 로 생성된 정보 확인
# 5. 1 ~ 4 번 과정을 arm64e Architecture symbol 추출 진행
# 6. 빌드명이 포함된 폴더 생성과 Symbol 폴더 이동
# 7. tar 압축 진행
# 8. python http server 구동


set -xe
if [ $# -lt 3 ];
then
    echo "USAGE: $0 {arm64_ipsw_file_name} {arm64e_ipsw_file_name} {os_version (build_name)}"
    exit 1
fi

# util function
function rm_dir() {
  FOLDER_LIST=$(find $BASE_DIR -mindepth 1 -maxdepth 1 -type d | grep -v "Symbols")
  for folder in "${FOLDER_LIST[@]}"; do
    rm -rf $folder
  done
}

# Variables
BASE_DIR=$(pwd)
arm64=$1
arm64e=$2
target=$3

# arm64 Architecture 심볼 추출 작업
ipsw extract -d $arm64
valid_cache=$(ls -lR | grep ^l | awk '{print $11}')
mv $BASE_DIR/$valid_cache $BASE_DIR/dyld_shared_cache_arm64
codesign -d -vvvv $BASE_DIR/dyld_shared_cache_arm64
dsc_extractor_4k $BASE_DIR/dyld_shared_cache_arm64 $BASE_DIR/Symbols
lipo -info $BASE_DIR/Symbols/System/Library/Messages/PlugIns/SMS.imservice/SMS

rm_dir
sleep 5s

# arm64e Architecture 심볼 추출 작업
ipsw extract -d $arm64e
valid_cache=$(ls -lR | grep ^l | awk '{print $11}')
mv $BASE_DIR/$valid_cache $BASE_DIR/dyld_shared_cache_arm64e
codesign -d -vvvv $BASE_DIR/dyld_shared_cache_arm64e
dsc_extractor_16k dyld_shared_cache_arm64e Symbols
lipo -info $BASE_DIR/Symbols/System/Library/Messages/PlugIns/SMS.imservice/SMS

rm_dir
rm -rf dyld_shared_cache_arm64 dyld_shared_cache_arm64e

# 압축
mkdir -p $BASE_DIR/"`echo $target`"
mv $BASE_DIR/Symbols $BASE_DIR/"`echo $target`"
tar czf "`echo $target`.tar.gz" "`echo $target`"

tar_size=$(du -s "`echo $target`.tar.gz" | awk '{print $1}')
echo "target_size: $tar_size"

exec python -m http.server
