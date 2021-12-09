#!/bin/bash

##
# Main entry for monorepository build.
# Triggers builds for all modified projects in order respecting their dependencies.
#
# Usage:
#   build.sh
##

set -e

# Find script directory (no support for symlinks)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Configuration with default values
: "${CI_TOOL:=github}"
: "${CI_PLUGIN:=$DIR/../plugins/${CI_TOOL}.sh}"

# Resolve commit range for current build
LAST_SUCCESSFUL_COMMIT=$(${CI_PLUGIN} hash last)
#LAST_SUCCESSFUL_COMMIT="d88f95dfe5835daf043d36c21d01c0d754e41538"
echo "Last commit: ${LAST_SUCCESSFUL_COMMIT}"
if [[ ${LAST_SUCCESSFUL_COMMIT} == "null" ]]; then
    COMMIT_RANGE=$GITHUB_REF
else
    COMMIT_RANGE="$(${CI_PLUGIN} hash current)..${LAST_SUCCESSFUL_COMMIT}"
fi
echo "Commit range: $COMMIT_RANGE"

# Ensure we have all changes from last successful build
if [[ -f $(git rev-parse --git-dir)/shallow ]]; then
    if [[ ${LAST_SUCCESSFUL_COMMIT} == "null" ]]; then
        git fetch --unshallow
    else
        DEPTH=1
        until git show ${LAST_SUCCESSFUL_COMMIT} > /dev/null 2>&1
        do
            DEPTH=$((DEPTH+5))
            echo "Last commit not fetched yet. Fetching depth $DEPTH."
            git fetch --depth=$DEPTH
        done
    fi
fi

# Collect all modified projects
#PROJECTS_TO_BUILD=$($DIR/list-projects-to-build.sh $COMMIT_RANGE)
PROJECTS_TO_BUILD=$(./pants --changed-since='origin/test_matrix' --changed-dependees=transitive list | xargs ./pants filter --target-type=pex_binary)

 If nothing to build inform and exit
if [[ -z "$PROJECTS_TO_BUILD" ]]; then
    echo "No projects to build"
    exit 0
fi


#echo "Following projects need to be built"
#echo -e "$PROJECTS_TO_BUILD"
# Build all modified projects

PARSED_PROJECTS=()
 #while read $PROJECT_TO_BUILD; do
#  PROJECT=$(echo -e $(basename $PROJECTS) | tr ":" " " | cut -d " " -f1)
#  echo $PROJECT
#  PARSED_PROJECTS=(${PARSED_PROJECTS[@]} "test")
#  PARSED_PROJECTS+=("first")
#    CI_PLUGIN=${CI_PLUGIN} $DIR/build-projects.sh ${PROJECTS}
#done;
while IFS= read -r PROJECT
do
    PROJECT_NAME=$(echo -e $(basename $PROJECT) | tr ":" " " | cut -d " " -f1)
    PARSED_PROJECTS+=($PROJECT_NAME)
done <<< "$PROJECTS_TO_BUILD"
#echo "${PARSED_PROJECTS[@]}"
#printf '%s' "${PARSED_PROJECTS[@]}" | jq -R . | jq -s -c 'add'
export OUTPUT=$(echo "${PARSED_PROJECTS[@]}" | tr ' ' ',')
#jq --compact-output --null-input '$PARSED_PROJECTS' --args "${PARSED_PROJECTS[@]}"