#!/bin/bash -eu
# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

# compile source
cd ./source
rm dng_xmp*
find . -name "*.cpp" -exec $CXX $CXXFLAGS -DqDNGUseLibJPEG=1 -DqDNGUseXMP=0 -DqDNGThreadSafe=1 -c {} \;
ar cr libdns_sdk.a *.o

# compile fuzzer
$CXX $CXXFLAGS $LIB_FUZZING_ENGINE ../fuzzer/dng_parser_fuzzer.cpp -o $OUT/dng_parser_fuzzer \
  ./libdns_sdk.a -I./ -l:libjpeg.a -lz

$CXX $CXXFLAGS $LIB_FUZZING_ENGINE $SRC/dng_stage_fuzzer.cpp -o $OUT/dng_stage_fuzzer \
  ./libdns_sdk.a -I./ -l:libjpeg.a -lz


sed -i 's/main/main2/g' $SRC/dng_sdk/source/dng_validate.cpp
sed -i 's/printf ("Val/\/\//g' $SRC/dng_sdk/source/dng_validate.cpp
sed -i 's/static//g' $SRC/dng_sdk/source/dng_validate.cpp

cat $SRC/dng_sdk/source/dng_validate.cpp $SRC/dng_validate_fuzzer.cpp >> $SRC/dng_validate_fuzzer.tmp
mv $SRC/dng_validate_fuzzer.tmp $SRC/dng_validate_fuzzer.cpp
$CXX $CXXFLAGS $LIB_FUZZING_ENGINE -DqDNGValidateTarget \
  $SRC/dng_sdk/source/dng_globals.cpp \
  $SRC/dng_validate_fuzzer.cpp \
  -o $OUT/dng_validate_fuzzer \
  ./libdns_sdk.a -I./ -l:libjpeg.a -lz

cat $SRC/dng_sdk/source/dng_validate.cpp $SRC/dng_fixed_validate_fuzzer.cpp >> $SRC/dng_fixed_validate_fuzzer.tmp
mv $SRC/dng_fixed_validate_fuzzer.tmp $SRC/dng_fixed_validate_fuzzer.cpp
$CXX $CXXFLAGS $LIB_FUZZING_ENGINE -DqDNGValidateTarget \
  $SRC/dng_sdk/source/dng_globals.cpp \
  $SRC/dng_fixed_validate_fuzzer.cpp \
  -o $OUT/dng_fixed_validate_fuzzer \
  ./libdns_sdk.a -I./ -l:libjpeg.a -lz

# move seeds
cd ../fuzzer/seeds/CVE_2020_9589
zip -q $OUT/dng_parser_fuzzer_seed_corpus.zip *.dng
zip -q $OUT/dng_stage_fuzzer_seed_corpus.zip *.dng
zip -q $OUT/dng_fixed_validate_fuzzer_seed_corpus.zip *.dng
