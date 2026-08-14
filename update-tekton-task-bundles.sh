#!/bin/bash

# Use this script to update the Tekton Task Bundle references used in a Pipeline or a PipelineRun.
#
# Update bundles in a specific YAML file:
# update-tekton-task-bundles.sh .tekton/build-pipeline.yaml
#
# Update bundles in all YAML files under .tekton/
# update-tekton-task-bundles.sh

set -euo pipefail

FILES=$@
if [[ -z "$FILES" ]]; then
    FILES=$(find .tekton/ -name "*.yaml")
fi

# Determine the flavor of yq and adjust yq commands accordingly
if [ -z "$(yq --version | grep mikefarah)" ]; then
   # Python yq
   YQ_FRAGMENT1='.. | select(type == "object" and has("resolver"))'
   YQ_FRAGMENT2='-r'
else
   # mikefarah yq
   YQ_FRAGMENT1='... | select(has("resolver"))'
   YQ_FRAGMENT2=''
fi

# Find existing image references
OLD_REFS="$(\
    yq "$YQ_FRAGMENT1 | .params // [] | .[] | select(.name == \"bundle\") | .value"  $FILES | \
    grep -v -- '---' | \
    sed 's/^"\(.*\)"$/\1/' | \
    sort -u \
)"

arg_new_bundles=()

# Find updates for image references
for old_ref in ${OLD_REFS}; do
    repo_tag="${old_ref%@*}"
    new_digest="$(skopeo inspect --no-tags docker://${repo_tag} | yq $YQ_FRAGMENT2 '.Digest')"
    new_ref="${repo_tag}@${new_digest}"
    [[ $new_ref == $old_ref ]] && continue
    echo "New digest found! $new_ref"
    arg_new_bundles+=(--new-bundle "$new_ref")
done

if [[ ${#arg_new_bundles[@]} = 0 ]]; then
    echo "All bundles are up-to-date."
    exit
fi

arg_pipeline_files=()
for file in $FILES; do
    arg_pipeline_files+=(--pipeline-file "$file")
done

pmt migrate ${arg_new_bundles[@]} ${arg_pipeline_files[@]}
