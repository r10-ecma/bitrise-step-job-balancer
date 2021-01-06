#!/usr/bin/env bash
# fail if any commands fails
set -e
# debug log
set -x
if [ -z "$app_cc_count" ]
then
    echo "\$app_cc_count is empty. Please add the variable on the Env Vars tab of the Workflow Editor and specify the number of builds that can run in parallel for this application"
    exit 1
else
    echo "\$app_cc_count is set to $app_cc_count"
fi
# Get currently running build count
json=$(curl -H 'Authorization: '$bitrise_access_token'' 'https://api.bitrise.io/v0.1/apps/'$BITRISE_APP_SLUG'/builds?status=0')
running_build_count=$(echo "${json}" | jq -r '.paging.total_item_count')
available_cc_count=$((app_cc_count - running_build_count + 1 ))
echo "Running build count for the owner: " + $running_build_count + "\nAvailable CC count: " + $available_cc_count
if [ $app_cc_count -gt $running_build_count ]
then
    echo "enough CCs are available, starting fan out" // do nothing as the fan-out can run smoothly    
else
    sleep $wait_time
    json=$(curl -H 'Authorization: '$bitrise_access_token'' 'https://api.bitrise.io/v0.1/apps/'$BITRISE_APP_SLUG'/builds?status=0')
    running_build_count=$(echo "${json}" | jq -r '.paging.total_item_count')
    if [ $app_cc_count -gt $running_build_count ]
    then
        echo "enough CCs are available, starting fan out" // do nothing as the fan-out can run smoothly    
    else
        echo "start the same build again"
        json=$(curl -X POST -H 'Authorization: '$bitrise_access_token'' 'https://api.bitrise.io/v0.1/apps/'$BITRISE_APP_SLUG'/builds' -d '{ "build_params": { "branch": "'$BITRISE_GIT_BRANCH'", "branch_dest": "'$BITRISEIO_GIT_BRANCH_DEST'", "branch_dest_repo_owner": "", "branch_repo_owner": "", "build_request_slug": "", "commit_hash": "'$BITRISE_GIT_COMMIT'", "commit_message": "", "commit_paths": [ { "added": [ "" ], "modified": [ "" ], "removed": [ "" ] } ], "diff_url": "", "environments": [], "pull_request_author": "", "pull_request_head_branch": "", "pull_request_id": "'$PULL_REQUEST_ID'", "pull_request_merge_branch": "'$BITRISEIO_PULL_REQUEST_MERGE_BRANCH'", "pull_request_repository_url": "", "skip_git_status_report": false, "tag": "", "workflow_id": "'$BITRISE_TRIGGERED_WORKFLOW_ID'" }, "hook_info": { "type": "bitrise" }}')
        echo "aborting current build"
        json=$(curl -X POST -H 'Authorization: '$bitrise_access_token'' 'https://api.bitrise.io/v0.1/apps/'$BITRISE_APP_SLUG'/builds/'$BITRISE_BUILD_SLUG'/abort' -d '{"abort_reason": "abort with abort_with_success=true test & skip_notifications=true", "abort_with_success": true,"skip_notifications": true}')
    fi
fi