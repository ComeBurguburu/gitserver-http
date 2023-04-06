#!/bin/bash

# Initializes Nginx and the git cgi scripts
# for git http-backend through fcgiwrap.
#
# Usage:
#   entrypoint <commands>
#
# Commands:
#   -start    starts the git server (nginx + fcgi)
#
#   -init     turns directories under `/var/lib/initial`
#             into bare repositories at `/repo`
# 

set -o errexit

readonly GIT_PROJECT_ROOT="/home/git"
readonly GIT_INITIAL_ROOT="/home/default_project"
readonly GIT_HTTP_EXPORT_ALL="true"
readonly GIT_USER="git"
readonly GIT_GROUP="git"

readonly FCGIPROGRAM="/usr/sbin/fcgiwrap"
readonly USERID="nginx"
readonly SOCKUSERID="$USERID"
readonly FCGISOCKET="/tmp/fcgiwrap.socket"


main() {
  mkdir -p $GIT_PROJECT_ROOT

  # Checks if $GIT_INITIAL_ROOT has files
  if [[ $(ls -A ${GIT_INITIAL_ROOT}) ]]; then
    initialize_initial_repositories
  fi
  initialize_services
}

initialize_services() {

  /usr/bin/spawn-fcgi \
    -s $FCGISOCKET \
    -F 4 \
    -u $USERID \
    -g $USERID \
    -U $USERID \
    -G $GIT_GROUP -- \
    "$FCGIPROGRAM"
  exec nginx
}

initialize_initial_repositories() {
  cd $GIT_INITIAL_ROOT
  for dir in $(find . -name "*" -type d -maxdepth 1 -mindepth 1); do
    echo "Initializing repository $dir"
    init_and_commit $dir
  done
}

init_and_commit() {

  local dir=$1

  if [[ -d $GIT_PROJECT_ROOT/${dir}.git ]]; then
    return 0
  fi

  local tmp_dir=$(mktemp -d)

  cp -r $dir/* $tmp_dir
  pushd . >/dev/null
  cd $tmp_dir

  if [[ -d "./.git" ]]; then
    rm -rf ./.git
  fi

  git init &>/dev/null
  git add --all . &>/dev/null
  git config --global user.name "some"
  git config --global user.email some@gmail.com
  git add . && git commit -m "first commit"  -a &>/dev/null
  git clone --bare $tmp_dir $GIT_PROJECT_ROOT/${dir}.git &>/dev/null

  rm -rf tmp_dir
  popd >/dev/null
}

main "$@"
