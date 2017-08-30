#!/usr/bin/env bash

readonly SCRIPT=$(basename "$0")
readonly VERSION='0.5.1'

usage() {
cat <<EOF
Usage:
  $SCRIPT [options]
  $SCRIPT -h | --help
  $SCRIPT --version

Options:
  -f --force                     Force download of picture. This will overwrite
                                 the picture if the filename already exists.
  -q --quiet                     Do not display log messages.
  -n --filename <file name>      The name of the downloaded picture. Defaults to
                                 the upstream name.
  -p --picturedir <picture dir>  The full path to the picture download dir.
                                 Will be created if it does not exist.
                                 [default: $HOME/Pictures/bing-wallpapers/]
  -s --size                      Preferred size of the photo to download
                                 [default:1920x1200]. If it is not existed, try
                                 to download the different sizes by the order:
                                 [1920x1200, 1920x1080, 1366x768]
  -d --day                       Day of the bing photo count from today.
                                 [-1, tomorrow; 0, today; 1, yesterday]
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
SIZES=("1920x1200" "1920x1080" "1366x768")
DAY="-1"
BING_HOME="https://www.bing.com"
GGREP="/usr/local/bin/grep"

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
            SIZES=("$2" "${SIZES[@]}")
            shift
            ;;
        -d|--day)
            DAY="$2"
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
API="${BING_HOME}/HPImageArchive.aspx?format=xml&idx=${DAY}&n=1"
ACTION="curl -sL \"${API}\" | \
        ${GGREP} -Po '(?<=\<urlBase\>)(.*?)(?=\</urlBase\>)'"
CODE="curl -o /dev/null --silent --head --write-out '%{http_code}\n'"
u="${BING_HOME}`eval $ACTION`"
for sz in "${SIZES[@]}"; do
    url="${u}_${sz}.jpg"
    http_code=`eval $CODE "$url"`
    if [ $http_code -ne 200 ]; then continue; fi
    if [ -z "$FILENAME" ]; then
        filename=$(echo "$url"|sed -e "s/.*\/\(.*\)/\1/")
    else
        filename="$FILENAME"
    fi
    if [ $FORCE ] || [ ! -f "$PICTURE_DIR/$filename" ]; then
        print_message "Downloading: $filename..."
        curl $CURL_QUIET -Lo "$PICTURE_DIR/$filename" "$url"
        "/Applications/Mission Control.app/Contents/MacOS/Mission Control"
        sleep 2
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
    break
done
