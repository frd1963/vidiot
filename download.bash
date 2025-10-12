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
VERBOSE=0
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
    local msg="${1}"
    local code="${2:-1}"
    echo "ERROR: "${msg}
    exit "${code}"
}

function enforce_param {
    local opt="${1:-unspecified}"
    local num="${2:-0}"
    local min="${3:-1}"
    if [[ "${min}" -gt "${num}" ]] ; then
        puke "option '${opt}' expects ${min} parameter(s), but ${num} provided" 10
    fi
}

function log {
    [ $VERBOSE -gt 0 ] && cat >&2
}

function logIt {
    echo "${@}" | log
}

# Process the args
CLI_CMD=()
POSITIONAL=()
while [[ $# -gt 0 ]] ; do
    option="${1}"
    shift

    # find non 'dash' options and group them as params for the current option
    params=()
    while [[ -n "${1}" && ! ${1} =~ ^- ]]; do
        params+=("${1}")
        shift
    done

    logIt "processing option '${option}' with params (${params[@]})"
    case $option in
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
            enforce_param "${option}" "${#params[@]}"
            V_EXT="${params[0]}"
            shift
        ;;
        -cb|--cookies-from-browser)
            enforce_param "${option}" "${#params[@]}"
            COOKIES_BROWSER_OPTION="--cookies-from-browser ${params[0]}"
        ;;
        -af|--audioformat)
            enforce_param "${option}" "${#params[@]}"
            A_EXT="${1}"
            shift
        ;;
        -vaf|--videoaudioformat)
            enforce_param "${option}" "${#params[@]}"
            VA_EXT="${1}"
            shift
        ;;
        -ab|--audiobitrate)
            enforce_param "${option}" "${#params[@]}"
            AUDIO_BITRATE="${1}"
            shift
        ;;
        -vab|--videoaudiobitrate)
            enforce_param "${option}" "${#params[@]}"
            VIDEO_AUDIO_BITRATE="${1}"
            shift
        ;;
        -Mh|--maxheight)
            enforce_param "${option}" "${#params[@]}"
            MAX_VID_HEIGHT="${1}"
            shift
        ;;
        -mh|--minheight)
            enforce_param "${option}" "${#params[@]}"
            MIN_VID_HEIGHT="${1}"
            shift
        ;;
        -v|--verbose)
            VERBOSE=1
        ;;
        -s|--sleeptime)
            enforce_param "${option}" "${#params[@]}"
            SLEEP_TIME="${1}"
            shift
        ;;
        -sim|--simulate)
            SIMULATE=1
        ;;
        -qd|--queuedir)
            enforce_param "${option}" "${#params[@]}"
            QUEUE_DIR="${1}"
            shift
        ;;
        -qp|--queuepattern)
            enforce_param "${option}" "${#params[@]}"
            QUEUE_PATTERN="${1}"
            shift
        ;;
        -d|--downloaddir)
            enforce_param "${option}" "${#params[@]}"
            DOWNLOAD_DIR="${1}"
            shift
        ;;
        -x|--executable)
            enforce_param "${option}" "${#params[@]}"
            DL_CMD="${1}"
            shift``
        ;;
        -n|--no_rm)
            RM_FILE=0
        ;;
        -x|--del-requests)
            keepReqsNum="${1:-0}"
            if [[ "${keepReqsNum}" =~ [^0-9] ]] ; then
                puke "option ${option} doesn't understand non-number parameter '${keepReqsNum}'" 10
            fi
            DEL_REQUESTS="${keepReqsNum}"
            DEL_EXIT="no"
        ;;
        -xx|--del-requests-exit)
            keepReqsNum="${1:-0}"
            if [[ "${keepReqsNum}" =~ [^0-9] ]] ; then
                puke "option ${option} doesn't understand non-number parameter '${keepReqsNum}'" 10
            fi
            DEL_REQUESTS="${keepReqsNum}"
            DEL_EXIT="yes"
        ;;
        -cli) CLI_CMD+="${params[@]}"
        ;;
        *)
            puke "Unknown option '${option}'"
        ;;
    esac
done

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

function getRequestFiles {
    local loc="${1:-${QUEUE_DIR}}"
    \ls -tr "${loc}"/${QUEUE_PATTERN} 2>/dev/null
}

function getNextFile {
    local loc="${1:-${QUEUE_DIR}}"
    local files file
    while IFS=\n read -r file; do
        files+=("${file}")
    done < <(getRequestFiles "${loc}")
    if [[ "${#files}" ]] ; then echo "${files[0]}"; fi
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

function listOldRequests {
    local keep="${1:-0}"
    ((keep++))
    getRequestFiles "${QUEUE_DIR}" | tail -n +"${keep}"
}

function deleteOldRequests {
    # find all existing requests, and delete all but the most recent ${DEL_REQUESTS}
    local keep="${1:-0}"
    local file
    local files2delete
    while IFS=\n read -r file; do
        logIt "found old file '${file}'"
        files2delete+=("${file}")
    done < <(listOldRequests "${keep}")
    logIt "files2delete: ("${files2delete[@]}")"
    for file in "${files2delete[@]}" ; do
        [[ -z "${file}" ]] && continue
        logIt "Removing old request file '${file}'"
        \rm "${file}" || puke "Unable to remove old request file '${file}'" 5
    done
    if [[ "${DEL_EXIT}" == "yes" ]] ; then 
        exit
    fi
}

function main {
    echo "skipping main"
    # deleteOldRequests
    # cd "$DOWNLOAD_DIR"
    # goGetEm
}

if [[ -n "${CLI_CMD}" ]] ; then
    logIt "running CLI_CMD='${CLI_CMD}"
    ${CLI_CMD}
else
    main
fi
