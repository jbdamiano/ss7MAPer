#!/bin/sh -x

set -e

git clone https://github.com/jbdamiano/ss7MAPer.git

cd ss7MAPer
sh ./prepare_local_build.sh
