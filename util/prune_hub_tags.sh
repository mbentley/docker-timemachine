#!/bin/bash

# get the date, in seconds, for when we should purge tags before
PURGE_DATE="$(date --date='-6 months' +%s)"

# get Docker Hub credentials
HUB_AUTH="$(jq -r '.auths."https://index.docker.io/v1/".auth' "${HOME}/.docker/config.json" | base64 -d)"

# make sure we received credentials
if [ -z "${HUB_AUTH}" ]
then
  echo "ERROR: authorization data not found (have you performed a \"docker login\")?"
  exit 1
else
  # get a token
  TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'"$(echo "${HUB_AUTH}" | awk -F ':' '{print $1}')"'", "password": "'"$(echo "${HUB_AUTH}" | awk -F ':' '{print $2}')"'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)
fi

# make sure we received a docker hub token
if [ -z "${TOKEN}" ]
then
  echo "ERROR: failed to get a Docker Hub auth token"
  exit 1
fi

# initialize default loop variables
TAG_PAGE="1"
NEXT_PAGE=""

while [ "${NEXT_PAGE}" != "null" ]
do
  # get a page of tags
  PAGE_OF_TAGS="$(curl -s -H "Authorization: JWT ${TOKEN}" "https://hub.docker.com/v2/repositories/mbentley/timemachine/tags?page=${TAG_PAGE}&page_size=50")"

  # set the next page variable
  NEXT_PAGE="$(echo "${PAGE_OF_TAGS}" | jq -r .next)"

  # add the tags from the page to the list of tags
  HUB_TAGS="${HUB_TAGS}
$(echo "${PAGE_OF_TAGS}" | jq -r '.results[] | .name + " " + .tag_last_pushed')"

  # increment the tag page
  TAG_PAGE=$((TAG_PAGE+1))
done

# trim off any blank lines from the list of tags
HUB_TAGS="$(echo "${HUB_TAGS}" | sed '/^[[:space:]]*$/d')"

while read -r TAG_NAME TAG_LAST_PUSHED
do
  # check to see if we should skip the tag
  if echo "${TAG_NAME}" | grep -qE '(^latest$)|(^afp$)|(^smb$)|(-arm64$)|(-amd64$)|(-armv7l$)'
  then
    echo "skip tag ${TAG_NAME}"
  else
    # convert the date to seconds
    TAG_LAST_PUSHED=$(date -d "${TAG_LAST_PUSHED}" +%s)

    # compare the tag last pushed date to the purge date cutoff
    if [ "${TAG_LAST_PUSHED}" -lt "${PURGE_DATE}" ]
    then
      # purge tag
      echo "tag age $(date -d "@${TAG_LAST_PUSHED}" +%Y-%m-%d), threshold $(date -d "@${PURGE_DATE}" +%Y-%m-%d), ${TAG_NAME}, removing"

      # delete the tag
      curl -H "Authorization: JWT ${TOKEN}" -X DELETE "https://hub.docker.com/v2/repositories/mbentley/timemachine/tags/${TAG_NAME}/"
    else
      # do not purge tag
      echo "tag age $(date -d "@${TAG_LAST_PUSHED}" +%Y-%m-%d), threshold $(date -d "@${PURGE_DATE}" +%Y-%m-%d), ${TAG_NAME}, NOT removing"
    fi
  fi
done < <(echo "${HUB_TAGS}")
