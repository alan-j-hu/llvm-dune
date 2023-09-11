#!/bin/sh

set -e
set -x

cd "$(dirname "$0")"
if test "$#" -ne 1; then
    echo "Usage: $0 <prefix>"
    exit 1
fi

PREFIX=$1

dune install "--prefix=$PREFIX" --release
