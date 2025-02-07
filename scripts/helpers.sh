#!/bin/bash

function datetime { 
  # return time formatted "2024-02-31_19-56-56"
  date +%F_%H-%M-%S
}

function getdomain {
  # sanitize links to "updates.signal.org"
  echo "$1" | sed 's?https://??' | sed 's:/.*::'
}

function slugify {
  # sanitize links to "https___updates.signal.org_android_latest.json"
  echo "$1" | sed 's-[:/?()]-_-g'
}

export -f datetime
export -f getdomain
export -f slugify

