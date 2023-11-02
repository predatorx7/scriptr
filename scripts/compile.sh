#!/usr/bin/env sh

# ./scripts/compile.sh <target-platform>;

rm -rf build/;
mkdir -p build/bin;

dart compile exe --output build/bin/scriptr --target-os $@ bin/scriptr.dart;
