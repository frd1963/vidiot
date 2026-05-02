#! /usr/bin/bash

AVFORMAT="${1}"
JS_FILE="generic_download.js"

function promptForFormat {

  # Define the choices
  options=("Video" "Audio" "Both" "Quit")

  # Set the prompt for the select statement
  PS3="Please choose which format you want: "

  # Use the select construct to present the menu
  select choice in "${options[@]}"; do
    case $choice in
        "Video")
            AVFORMAT='video'
            break
            ;;
        "Audio")
            AVFORMAT='audio'
            break
            ;;
        "Both")
            AVFORMAT='both'
            break
            ;;
        "Quit")
            echo "Exiting."
            exit
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
  done
}

function oneLine {
  tr '\012' ' '
}

function reFormat {
  local sedString="s/\%FORMAT\%/${AVFORMAT}/g"
  sed -e "${sedString}"
}

function wrapIt {
  echo -n "javascript:( "
  cat
  echo " )('%FORMAT%')"
}

function getJs {
  cat "${JS_FILE}"
}

function showFile {
  local filename="${1}"
  cat << END
  
:::::::::::::: ${filename} ::::::::::::::
  $(cat ${filename})
-----------------------------------------
  
END
}

if [[ -z "${AVFORMAT}" ]] ; then
  promptForFormat
fi

if [[ "${AVFORMAT}" == "both" ]] ; then
  bash $0 video
  bash $0 audio
else
  filename="$(dirname "${0}")/bookmark_${AVFORMAT}.txt"
  getJs | wrapIt | reFormat | oneLine > "${filename}"
  showFile "${filename}"
fi
