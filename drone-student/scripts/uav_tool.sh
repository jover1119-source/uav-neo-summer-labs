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
      echo "Creating a JupyterLab server..."
      jupyter lab --no-browser
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

    open_sim)
      # Locate the simulator folder. DRONE_ABSOLUTE_PATH is the drone-student dir;
      # the simulator lives one level up alongside it (and on Windows, that path
      # is a symlink into /mnt/c/Users/<user>/UAVNeo-Simulator).
      local sim_root="$(dirname "$DRONE_ABSOLUTE_PATH")/UAVNeo-Simulator"
      if [ ! -d "$sim_root" ]; then
        echo "Error: simulator folder not found at ${sim_root}."
        echo "Run setup.sh or 'bash \$(dirname \"\$DRONE_ABSOLUTE_PATH\")/drone-student/scripts/update.sh' to install it."
        return 1
      fi

      # The simulator builds are packaged as UAVSim_<Platform>_v<version>/.
      # Pick the first match so version bumps don't break this command.
      local sim_build
      sim_build=$(find -L "$sim_root" -maxdepth 1 -mindepth 1 -type d -name 'UAVSim_*' | head -n1)
      if [ -z "$sim_build" ]; then
        echo "Error: no UAVSim_* build folder found inside ${sim_root}."
        return 1
      fi

      # Detect host OS and launch the right binary.
      if grep -qi "microsoft" /proc/version 2>/dev/null; then
        # WSL — invoke the .exe through cmd.exe so Windows owns the process and
        # resolves DLLs from a real NTFS path (not a \\wsl.localhost UNC path).
        local exe_path="${sim_build}/UAVSim.exe"
        if [ ! -f "$exe_path" ]; then
          echo "Error: UAVSim.exe not found at ${exe_path}."
          return 1
        fi
        local win_path
        win_path=$(wslpath -w "$exe_path" 2>/dev/null)
        if [ -z "$win_path" ]; then
          echo "Error: could not translate ${exe_path} to a Windows path via wslpath."
          return 1
        fi
        echo "Launching simulator: ${win_path}"
        ( cd "$sim_build" && cmd.exe /c start "" "$win_path" ) >/dev/null 2>&1 &
        disown 2>/dev/null
      elif [ "$(uname)" = "Darwin" ]; then
        local app_path
        app_path=$(find -L "$sim_build" -maxdepth 1 -mindepth 1 -name 'UAVSim*.app' | head -n1)
        if [ -z "$app_path" ]; then
          echo "Error: UAVSim*.app bundle not found in ${sim_build}."
          return 1
        fi
        echo "Launching simulator: ${app_path}"
        open "$app_path"
      elif [ "$(uname)" = "Linux" ]; then
        local lin_exe
        lin_exe=$(find -L "$sim_build" -maxdepth 1 -mindepth 1 -type f \( -name 'UAVSim.x86_64' -o -name 'UAVSim' \) | head -n1)
        if [ -z "$lin_exe" ]; then
          echo "Error: UAVSim Linux binary not found in ${sim_build}."
          return 1
        fi
        chmod +x "$lin_exe" 2>/dev/null
        echo "Launching simulator: ${lin_exe}"
        ( cd "$sim_build" && "$lin_exe" ) >/dev/null 2>&1 &
        disown 2>/dev/null
      else
        echo "Error: unrecognized OS. 'drone open_sim' supports Windows (WSL), Mac, and Linux."
        return 1
      fi
      ;;

    open_sim_folder)
      local sim_root="$(dirname "$DRONE_ABSOLUTE_PATH")/UAVNeo-Simulator"
      if [ ! -d "$sim_root" ]; then
        echo "Error: simulator folder not found at ${sim_root}."
        return 1
      fi

      if grep -qi "microsoft" /proc/version 2>/dev/null; then
        # Resolve the symlink so Explorer opens the real /mnt/c path, not \\wsl.localhost.
        local real_root
        real_root=$(readlink -f "$sim_root")
        local win_path
        win_path=$(wslpath -w "$real_root" 2>/dev/null)
        if [ -z "$win_path" ]; then
          echo "Error: could not translate ${real_root} to a Windows path."
          return 1
        fi
        echo "Opening folder: ${win_path}"
        explorer.exe "$win_path" >/dev/null 2>&1 &
        disown 2>/dev/null
      elif [ "$(uname)" = "Darwin" ]; then
        echo "Opening folder: ${sim_root}"
        open "$sim_root"
      elif [ "$(uname)" = "Linux" ]; then
        if ! command -v xdg-open >/dev/null 2>&1; then
          echo "Error: xdg-open not found. Install xdg-utils or open manually: ${sim_root}"
          return 1
        fi
        echo "Opening folder: ${sim_root}"
        xdg-open "$sim_root" >/dev/null 2>&1 &
        disown 2>/dev/null
      else
        echo "Error: unrecognized OS. 'drone open_sim_folder' supports Windows (WSL), Mac, and Linux."
        return 1
      fi
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
      echo "  drone jupyter             starts a JupyterLab server in the drone labs directory."
      echo "  drone remove              removes your team directory from your drone."
      echo "  drone setup               sets up your team directory on your drone."
      echo "  drone sim <file.py>       runs the specified drone program with the simulator."
      echo "  drone open_sim            launches the UAVNeo simulator GUI."
      echo "  drone open_sim_folder     opens the simulator folder in your file manager."
      echo "  drone sync [labs|library|all]  copies local files to your drone with rsync."
      echo "  drone backup              downloads drone code to a local backup folder."
      echo "  drone test                prints config to check if the drone tool is working."
      ;;

    *)
      echo "That was not a recognized drone command. Run 'drone help' for a list of commands."
      ;;
  esac
}
