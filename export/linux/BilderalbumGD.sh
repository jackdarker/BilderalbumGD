#!/bin/sh
printf '\033c\033]0;%s\a' BilderalbumGD
base_path="$(dirname "$(realpath "$0")")"
"$base_path/BilderalbumGD.x86_64" "$@"
