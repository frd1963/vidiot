#!/usr/bin/env bash

# Set Defaults
#DL_CMD="/c/Users/Public/Music/youtube-dl.exe"
#DL_CMD="youtube-dl"
DL_CMD="/opt/homebrew/bin/yt-dlp"
MIN_VID_HEIGHT=10
MAX_VID_HEIGHT=720
AUDIO_BITRATE="320k"
VIDEO_AUDIO_BITRATE="320k"
V_EXT="mp4"
A_EXT="mp3"
VA_EXT="m4a"
VERBOSE=1
DATA_DELIM="|"
QUEUE_DIR="${HOME}/Downloads/"
DOWNLOAD_DIR="${QUEUE_DIR}/DownloadedMusic"
QUEUE_PATTERN="VIDIOTQ_*.tsv"
SLEEP_TIME=5
LOOP=0
RM_FILE=1
SIMULATE=0
MTIME="--no-mtime"
PLAYLIST="yes"
COOKIES_BROWSER_OPTION=""

function puke {
    echo "ERROR: "${1}
    exit 1
}

# Process the args
POSITIONAL=()
while [[ $# -gt 0 ]] ; do
    key="${1}"
    shift
    case $key in
        -l|--loop)
            LOOP=1
        ;;
        -np|--noplaylist)
            PLAYLIST="no"
        ;;
        -mt|--modifytimestamp)
            MTIME=""
        ;;
        -vf|--videoformat)
            V_EXT="${1}"
            shift
        ;;
        -cb|--cookies-from-browser)
            COOKIES_BROWSER_OPTION="--cookies-from-browser ${1}"
            shift
        ;;
        -af|--audioformat)
            A_EXT="${1}"
            shift
        ;;
        -vaf|--videoaudioformat)
            VA_EXT="${1}"
            shift
        ;;
        -ab|--audiobitrate)
            AUDIO_BITRATE="${1}"
            shift
        ;;
        -vab|--videoaudiobitrate)
            VIDEO_AUDIO_BITRATE="${1}"
            shift
        ;;
        -Mh|--maxheight)
            MAX_VID_HEIGHT="${1}"
            shift
        ;;
        -mh|--minheight)
            MIN_VID_HEIGHT="${1}"
            shift
        ;;
        -v|--verbose)
            VERBOSE=1
        ;;
        -s|--sleeptime)
            SLEEP_TIME="${1}"
            shift
        ;;
        -sim|--simulate)
            SIMULATE=1
        ;;
        -qd|--queuedir)
            QUEUE_DIR="${1}"
            shift
        ;;
        -qp|--queuepattern)
            QUEUE_PATTERN="${1}"
            shift
        ;;
        -d|--downloaddir)
            DOWNLOAD_DIR="${1}"
            shift
        ;;
        -x|--executable)
            DL_CMD="${1}"
            shift
        ;;
        -n|--no_rm)
            RM_FILE=0
        ;;
        *)
            puke "Unknown option '${key}'"
        ;;
    esac
done

function log {
    [ $VERBOSE -gt 0 ] && cat
}

# function getFormats
function downloadMp3 {
    local url="${1}"
    local CMD="${DL_CMD} -x ${MTIME} \
        --${PLAYLIST}-playlist \
        ${COOKIE_BROWSER_OPTION} \
        --output '%(title)s.%(ext)s' \
        --audio-quality $AUDIO_BITRATE \
        --audio-format $A_EXT \
        '${url}'"
    if [[ $VERBOSE -gt 0 ]] ; then echo "$CMD" | log; fi
    if [[ $SIMULATE -gt 0 ]] ; then
        echo "Simulate downloading audio '$url'" | log
    else
        echo "Downloading audio '$url'" | log
        echo $CMD | bash
        local status=$?
        if [[ $status -gt 0 ]] ; then
            echo "'${DL_CMD}' exited with status=${status}"
            ${DL_CMD} -F "$url"
            puke "Failed to download audio '$url'"
        fi
    fi
}

function downloadVideo {
    local url="${1}"
    local skipAV1="[vcodec!*=av01]"
    local formatString="bestvideo[height<=${MAX_VID_HEIGHT}][height>=${MIN_VID_HEIGHT}][ext=${V_EXT}]${skipAV1}+bestaudio[ext=${VA_EXT}]"
    local CMD="${DL_CMD} ${MTIME} \
        --${PLAYLIST}-playlist \
        --output '%(title)s.%(ext)s' \
        --format '${formatString}' \
        '${url}'"
    if [[ $VERBOSE -gt 0 ]] ; then echo "$CMD" | log; fi
    if [[ $SIMULATE -gt 0 ]] ; then
        echo "Simulate downloading video '$url'" | log
    else
        echo "Downloading video '$url'" | log
        echo $CMD | bash
        local status=$?
        if [[ $status -gt 0 ]] ; then
            echo "'${DL_CMD}' exited with status=${status}"
            ${DL_CMD} -F "$url"
            puke "Failed to download audio '$url'"
        fi
    fi
}

function process {
    local filename=${1}
    local avformat=$(cat "${filename}" | cut -d"$DATA_DELIM" -f1)
    local url=$(cat "${filename}" | cut -d"$DATA_DELIM" -f2)
    local name=$(cat "${filename}" | cut -d"$DATA_DELIM" -f3-)

    log << END
file: $filename
    avformat: ${avformat}
    url:    ${url}
    name:   ${name}
END

    case $avformat in 
    audio)
        downloadMp3 $url
        ;;
    video)
        downloadVideo $url
        ;;
    *)
        puke "Unrecognized format '${avformat}'"
        ;;
    esac
    if [[ $RM_FILE -gt 0 ]] ; then
        echo "Removing '$filename'" | log
        \rm "${filename}"
    fi
    echo "Finished downloading $url" | log
}

function getNextFile {
    local loc="${1}"
    \ls -tr "${loc}"/${QUEUE_PATTERN} 2>/dev/null| head -1 
}

function goGetEm {
    # Look for files
    while [[ 1 -gt 0 ]] ; do
        filename=$(getNextFile "$QUEUE_DIR")
        # if no files, then either sleep to try again, or exit
        if [[ -z "$filename" ]] ; then
            if [[ $LOOP -gt 0 ]] ; then
                sleep $SLEEP_TIME
            else
                echo "No more files to process" | log
                break
            fi
        else
            process "${filename}"
        fi
    done
}

cd "$DOWNLOAD_DIR"
goGetEm
