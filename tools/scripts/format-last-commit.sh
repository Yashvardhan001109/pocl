#!/usr/bin/env bash

GITROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "must be run in git repo"
  exit 1
fi

SCRIPTPATH=$( realpath "$0"  )
RELPATH=$(dirname "$SCRIPTPATH")

# cd to root directory of the git repo
pushd ${GITROOT} > /dev/null

case "$(git describe --always --dirty=-DIRTY)" in
  *-DIRTY)
    echo "There are uncommitted changes - aborting."
    exit 1
esac

PATCHY=$(mktemp /tmp/pocl.XXXXXXXX.patch)
trap "rm -f $PATCHY" EXIT

git show -U0 --no-color >$PATCHY

SCRIPTPATH=$( realpath "$0"  )
RELPATH=$(dirname "$SCRIPTPATH")

$RELPATH/clang-format-diff.py -regex '.*(\.h$|\.c$|\.cl$)' -i -p1 -style=file:$RELPATH/style.GNU <$PATCHY
$RELPATH/clang-format-diff.py -regex '(.*(\.hpp$|\.hh$|\.cc$|\.cpp$))|(lib/llvmopencl/.*)|(lib/CL/devices/tce/.*)' -i -p1 -style LLVM <$PATCHY

if [ -z "$(git diff)" ]; then
  echo "No changes."
  exit 0
fi

# cd back whence we were previously
popd > /dev/null
