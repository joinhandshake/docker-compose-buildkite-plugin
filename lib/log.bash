#!/bin/bash

log() {
  msg="SIG $1 received, process exiting"
  echo "${msg}"
  buildkite-agent meta-data set "dd_tags.job-signal-${BUILDKITE_STEP_KEY}" "$1"
  buildkite-agent meta-data set "dd_tags.step-error-code-${BUILDKITE_STEP_KEY}" "$1"
  buildkite-agent meta-data set "dd_tags.job-error-code-${BUILDKITE_JOB_ID}" "$1"

  echo "$(pidof buildkite-agent) is the pid of the buildkite agent" || true

  send_job_signaled_to_dd "${msg}" "${1}"
}

send_job_signaled_to_dd() {
  send_event_to_dd '{ "title": "Job '"${BUILDKITE_STEP_KEY}"' received signal", "text": "'"${1}"'", "alert_type": "error", "tags": [ "ci:job_signal", "exit_status:'"${2}"'", "job_name:'"${BUILDKITE_STEP_KEY}"'", "build_id:'"${BUILDKITE_BUILD_ID}"'", "branch:'"${BUILDKITE_BRANCH}"'", "hs_source:docker_compose_plugin", "env:ci" ] }'
}

send_event_to_dd() {
  if command -v curl >/dev/null 2>&1; then
    echo "Using curl to send event to Datadog"
    curl -X POST "https://api.datadoghq.com/api/v1/events" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -H "DD-API-KEY: ${DD_API_KEY}" \
      -d "$1"
  elif command -v wget >/dev/null 2>&1; then
    echo "Using wget to send event to Datadog"
    wget \
      --header="Accept: application/json" \
      --header="Content-Type: application/json" \
      --header="DD-API-KEY: ${DD_API_KEY}" \
      --post-data="$1" \
      --output-document - \
      https://api.datadoghq.com/api/v1/events
  else
    echo "No suitable network tool found to send event to Datadog"
    exit 1
  fi
}
