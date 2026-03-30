#!/bin/bash
# Creates the drone tool for easily using and communicating with a drone

drone() {
  if [ "$DRONE_CONFIG_LOADED" != "TRUE" ]; then
    echo "Error: unable to find your local .config file.  Please make sure that you setup the drone tool correctly."
    echo "Go to \"https://github.com/MITUavNeo/uav-neo-installer\" for setup instructions."
    return 1
  fi

  local DRONE_DESTINATION_PATH="/home/uav/jupyter_ws/${DRONE_TEAM}"

  case "$1" in
    cd)
      cd "$DRONE_ABSOLUTE_PATH"/labs || return
      ;;

    connect)
      echo "Attempting to connect to drone (${DRONE_IP})..."
      ssh -t uav@"$DRONE_IP" "cd ${DRONE_DESTINATION_PATH} && export DISPLAY=:0 && bash"
      ;;

    jupyter)
      local prev_dir="$PWD"
      cd "$DRONE_ABSOLUTE_PATH"/labs || return
      echo "Creating a Jupyter server..."
      jupyter-notebook --no-browser
      cd "$prev_dir" || return
      ;;

    remove)
      echo "This will permanently delete your team directory (${DRONE_DESTINATION_PATH}) on the drone."
      read -r -p "Are you sure? [y/N] " confirm
      if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo "Removing your team directory from your drone..."
        ssh uav@"$DRONE_IP" "cd /home/uav/jupyter_ws/ && rm -rf ${DRONE_TEAM}"
      else
        echo "Cancelled."
      fi
      ;;

    setup)
      echo "Creating your team directory (${DRONE_DESTINATION_PATH}) on your drone..."
      ssh uav@"$DRONE_IP" mkdir -p "$DRONE_DESTINATION_PATH"
      drone sync all
      ;;

    sim)
      if [ $# -lt 2 ]; then
        echo "Usage: drone sim <filename.py> [additional arguments...]"
        return 1
      fi
      shift  # remove "sim" from args
      local script="$1"; shift  # grab the filename
      python3 "$script" -s "$@"
      ;;

    backup)
      local prev_dir="$PWD"
      cd "$DRONE_ABSOLUTE_PATH" || return

      if [ ! -d ".backup" ]; then
        echo "Backup folder not found, creating one now..."
        mkdir ./.backup
      fi

      local timestamp
      timestamp="$(date '+%Y%m%d_%H%M%S')"
      local backup_dir=".backup/${timestamp}"

      mkdir "$backup_dir"
      echo "Current date: $(date)" > "$backup_dir/info.txt"
      echo "Drone ip: $DRONE_IP" >> "$backup_dir/info.txt"
      echo "Drone team: $DRONE_TEAM" >> "$backup_dir/info.txt"

      echo "Backup location: $DRONE_ABSOLUTE_PATH/$backup_dir"
      echo "Downloading files now..."
      rsync -avP uav@"$DRONE_IP":/home/uav/jupyter_ws "$DRONE_ABSOLUTE_PATH/$backup_dir"

      cd "$prev_dir" || return
      ;;

    sync)
      if [ $# -lt 2 ]; then
        echo "Usage: drone sync [labs|library|all]"
        return 1
      fi
      local valid_command=false
      if [ "$2" = "library" ] || [ "$2" = "all" ]; then
        echo "Copying your local copy of the drone library to your drone (${DRONE_IP})..."
        rsync -azP --delete "$DRONE_ABSOLUTE_PATH"/library uav@"$DRONE_IP":"$DRONE_DESTINATION_PATH"
        valid_command=true
      fi
      if [ "$2" = "labs" ] || [ "$2" = "all" ]; then
        echo "Copying your local copy of the drone labs to your drone (${DRONE_IP})..."
        rsync -azP --delete "$DRONE_ABSOLUTE_PATH"/labs uav@"$DRONE_IP":"$DRONE_DESTINATION_PATH"
        valid_command=true
      fi
      if [ "$valid_command" = false ]; then
        echo "'${2}' is not a recognized sync target. Options: labs, library, all"
      fi
      ;;

    test)
      echo "drone tool set up successfully!"
      echo "  DRONE_ABSOLUTE_PATH: ${DRONE_ABSOLUTE_PATH}"
      echo "  DRONE_IP: ${DRONE_IP}"
      echo "  DRONE_TEAM: ${DRONE_TEAM}"
      ;;

    help)
      echo "The drone tool helps your computer communicate with your drone."
      echo ""
      echo "Supported commands:"
      echo "  drone cd                  move to the drone labs directory on your computer."
      echo "  drone connect             connects to your drone with ssh."
      echo "  drone help                prints this help message."
      echo "  drone jupyter             starts a jupyter server in the drone labs directory."
      echo "  drone remove              removes your team directory from your drone."
      echo "  drone setup               sets up your team directory on your drone."
      echo "  drone sim <file.py>       runs the specified drone program with the simulator."
      echo "  drone sync [labs|library|all]  copies local files to your drone with rsync."
      echo "  drone backup              downloads drone code to a local backup folder."
      echo "  drone test                prints config to check if the drone tool is working."
      ;;

    *)
      echo "That was not a recognized drone command. Run 'drone help' for a list of commands."
      ;;
  esac
}
