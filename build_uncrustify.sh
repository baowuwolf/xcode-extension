#!/usr/bin/env bash

#!/usr/bin/env bash
#
# comment here
#

# "$@" = "$1" "$2" "$3" ... "$n"
# "$*" = "$1y$2y$3y...$n", where y is the value of IFS variable i.e. 
# "$*" is one long string and $IFS act as an separator or token delimiters.
# IFS='\n\t'

set -euo pipefail
# set -o xtrace

declare -r script_path="${BASH_SOURCE[0]}"
#declare -r script_dir="${script_path%/*}"
declare -r script_file="${script_path##*/}"

# path="dir/basename.ext"
# dir="${path%/*}"
# filename="${path##*/}" # basename.ext
# basename="${path%\.*}"
# ext=${path##*.}


info() { printf "\\e[1m\\e[38;5;14m✔ %s\\e[0m\\n" "$@"; }
warn() { printf "\\e[1m\\e[38;5;148m➜️ %s\\e[0m\\n" "$@"; }
error(){ printf "\\e[1m\\e[38;5;196m✖ %s\\e[0m\\n" "$@"; }

die() {
  local last_error=$?
  if [[ $1 =~ ^[0-9]+$ ]]; then
  	last_error=$1
  	shift
  fi
  error "${script_file}:${BASH_LINENO[0]} ${FUNCNAME[1]}(${last_error})>$*" >&2
  exit "$last_error"
}

cd uncrustify || die "uncrustify dir not exist"

if [[ -d build ]]; then
	rm -rf build
fi
mkdir build	

cd build || die "build dir not exist"

cmake .. || die "cmake failed"
make || die "make failed"

cp -f uncrustify ../../RunWhenSave