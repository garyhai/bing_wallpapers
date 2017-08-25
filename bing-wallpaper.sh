#!/usr/bin/env bash

readonly SCRIPT=$(basename "$0")
readonly VERSION='0.2.0'

usage() {
cat <<EOF
Usage:
  $SCRIPT [options]
  $SCRIPT -h | --help
  $SCRIPT --version

Options:
  -f --force                     Force download of picture. This will overwrite
                                 the picture if the filename already exists.
  -s --size                      Size of the photos. [default:1920x1080]
                                 [1920x1200, 1920x1080, 1366x768]
  -d --day                       Day of the bing photo before now. [default: 0]
  -c --count                     Count of photos to fetch. [default: 1]
  -q --quiet                     Do not display log messages.
  -n --filename <file name>      The name of the downloaded picture. Defaults to
                                 the upstream name.
  -p --picturedir <picture dir>  The full path to the picture download dir.
                                 Will be created if it does not exist.
                                 [default: $HOME/Pictures/bing-wallpapers/]
  -h --help                      Show this screen.
  --version                      Show version.
EOF
}

print_message() {
    if [ ! "$QUIET" ]; then
        printf "%s\n" "${1}"
    fi
}

# Defaults
PICTURE_DIR="$HOME/Pictures/bing-wallpapers/"
SIZE="1920x1080"
DAY="0"
COUNT="1"
BING_HOME="https://www.bing.com"

# Option parsing
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -p|--picturedir)
            PICTURE_DIR="$2"
            shift
            ;;
        -n|--filename)
            FILENAME="$2"
            shift
            ;;
        -s|--size)
            SIZE="$2"
            shift
            ;;
        -d|--day)
            DAY="$2"
            shift
            ;;
        -c|--count)
            COUNT="$2"
            shift
            ;;
        -f|--force)
            FORCE=true
            ;;
        -q|--quiet)
            QUIET=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --version)
            printf "%s\n" $VERSION
            exit 0
            ;;
        *)
            (>&2 printf "Unknown parameter: %s\n" "$1")
            usage
            exit 1
            ;;
    esac
    shift
done

# Set options
[ $QUIET ] && CURL_QUIET='-s'

# Create picture directory if it doesn't already exist
mkdir -p "${PICTURE_DIR}"

# Parse bing.com and acquire picture URL(s)
API="${BING_HOME}/HPImageArchive.aspx?format=xml&idx=$DAY&n=$COUNT"
ACTION="curl -sL \"${API}\" | \
        ggrep -Po '(?<=\<urlBase\>)(.*?)(?=\</urlBase\>)'"
urls=( `eval $ACTION`)
for p in "${urls[@]}"; do
    url="${BING_HOME}${p}_${SIZE}.jpg"
    if [ -z "$FILENAME" ]; then
        filename=$(echo "$url"|sed -e "s/.*\/\(.*\)/\1/")
    else
        filename="$FILENAME"
    fi
    if [ $FORCE ] || [ ! -f "$PICTURE_DIR/$filename" ]; then
        print_message "Downloading: $filename..."
        curl $CURL_QUIET -Lo "$PICTURE_DIR/$filename" "$url"
        "/Applications/Mission Control.app/Contents/MacOS/Mission Control"
        sleep 1
        osascript -e "tell application \"System Events\" \
                      to set properties of desktops to \
                      {picture rotation:0, \
                       picture : \"$PICTURE_DIR/$filename\"}"
    else
        print_message "Skipping: $filename..."
        "/Applications/Mission Control.app/Contents/MacOS/Mission Control"
        osascript -e "tell application \"System Events\" \
                      to set picture rotation of desktops to 1"
    fi
done
