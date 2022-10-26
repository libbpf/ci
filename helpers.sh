# shellcheck shell=bash

# $1 - start or end
# $2 - fold identifier, no spaces
# $3 - fold section description
foldable() {
  local YELLOW='\033[1;33m'
  local NOCOLOR='\033[0m'
  if [ $1 = "start" ]; then
    line="::group::$2"
    if [ ! -z "${3:-}" ]; then
      line="$line - ${YELLOW}$3${NOCOLOR}"
    fi
  else
    line="::endgroup::"
  fi
  echo -e "$line"
}

__print() {
  local TITLE=""
  if [[ -n $2 ]]; then
      TITLE=" title=$2"
  fi
  echo "::$1${TITLE}::$3"
}

# $1 - title
# $2 - message
print_error() {
  __print error $1 $2
}

# $1 - title
# $2 - message
print_notice() {
  __print notice $1 $2
}

# No arguments
llvm_default_version() {
  echo "16"
}

# $1 - toolchain name
llvm_version() {
  local toolchain="$1"
  local toolchain_name="$(echo $toolchain | cut -d '-' -f 1)"
  local toolchain_version="$(echo $toolchain | cut -d '-' -f 2)"

  if [ "$toolchain_name" == "llvm" ]; then
    echo "$toolchain_version"
    return 0
  else
    llvm_default_version
    return 1
  fi
}
