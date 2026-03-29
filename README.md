# uav-neo-installer
Template repository for native UAV Neo installation on local computer

---

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Updating](#updating)
- [Troubleshooting](#troubleshooting)
  - [Setup log files](#setup-log-files)
  - [Simulator won't connect (Windows/WSL2)](#simulator-wont-connect-windowswsl2)
  - [Python 3.9 fails to install](#python-39-fails-to-install)
  - [Virtual environment issues](#virtual-environment-issues)
  - [drone command not found](#drone-command-not-found)

---

## Prerequisites

- **Windows**: Windows 10/11 with [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) installed (Ubuntu 22.04 recommended)
- **Mac**: macOS with a terminal (Homebrew will be installed automatically)
- **Linux**: Ubuntu 22.04 or 24.04 recommended

The setup script will automatically install Python 3.9, a virtual environment, and all required dependencies.

---

## Installation

1. Clone the install repository into your computer (entry point)

```sh
git clone https://github.com/MITUavNeo/uav-neo-installer.git
```

2. Run the installer script

```sh
bash uav-neo-installer/drone-student/scripts/setup.sh
```

3. When prompted, select your operating system and course curriculum.

```sh
Welcome to the UAV Neo Drone command-line installer for Windows, Mac, and Linux.
[1/3] Select your operating system: [windows, mac, linux]
1) windows
2) mac
3) linux
#? 1

[2/3] Select your course curriculum: [oneshot, outreach]
1) oneshot
2) outreach
#? 1

[3/3] Installing all drone libraries and dependencies...
```

4. Enter your sudo password and wait for the installation to finish. The script will automatically:
   - Clone the simulator, library, and lab files
   - Create a Python 3.9 virtual environment
   - Install all pip dependencies from `requirements.txt`
   - Configure your shell environment

5. **Windows only (WSL2):** The setup script will display an orange warning with a PowerShell command to configure your Windows Firewall. Open **PowerShell as Administrator** on Windows and run the command shown. This is required for the simulator to communicate with your Python scripts over the network. You only need to do this once.

6. At the end of setup, a post-installation check will run automatically. All 10 checks should show `[PASS]`. If any show `[FAIL]`, review the log file printed in the installation summary and contact your instructor.

**Successful setup example (Windows):**
```
==========================================================================
[IMPORTANT] Windows Firewall Configuration Required
==========================================================================
WSL2 requires a Windows Firewall rule to allow the UAVNeo Simulator to
communicate with your Python scripts. Without this rule, the simulator
may fail to connect when your computer is connected to the internet.

Please open PowerShell as Administrator on Windows and run:

  New-NetFirewallRule -DisplayName "WSL2 UAVNeo Simulator" -Direction Inbound -InterfaceAlias "vEthernet (WSL)" -Action Allow -Protocol UDP -LocalPort 5064-5065

You only need to run this command once.
==========================================================================

Running post-setup checks...
==========================================================================
```
```diff
+  [PASS] Simulator folder exists
+  [PASS] Labs folder exists
+  [PASS] Library folder exists
+  [PASS] Virtual environment exists
+  [PASS] Shell config added to ~/.bashrc
+  [PASS] .local_bashrc.sh created
+  [PASS] .config file created
+  [PASS] Drone tool is working
+  [PASS] No command failures detected in log file
+  [PASS] All Python dependencies installed
+
+  All 10 checks passed!
```
```
==========================================================================

======================== INSTALLATION SUMMARY ========================
  Platform:         windows
  Curriculum:       outreach
  Install location: /home/user/uav-neo-installer
  Log file:         /home/user/uav-neo-installer/drone-student/scripts/.logs/setup_2026-03-29_18-41-11.log
  Duration:         0m 48s
======================================================================

##########################################################################
##                                                                      ##
##   Run  source ~/.bashrc  or open a new terminal to finish setup.     ##
##                                                                      ##
##########################################################################

UAV Neo Drone Setup Complete.
```

**If something goes wrong**, you may see output like:
```diff
+  [PASS] Simulator folder exists
+  [PASS] Labs folder exists
+  [PASS] Library folder exists
-  [FAIL] Virtual environment not found
+  [PASS] Shell config added to ~/.bashrc
+  [PASS] .local_bashrc.sh created
+  [PASS] .config file created
+  [PASS] Drone tool is working
+  [PASS] No command failures detected in log file
-  [FAIL] Cannot verify dependencies — virtual environment not found
-
-  2 of 10 checks failed. Review the log: /home/user/.../setup_2026-03-29_18-41-11.log
```

If any checks fail, share the log file (found in `drone-student/scripts/.logs/`) with your instructor for help.

**If Python 3.9 fails to install**, the script will stop early with:
```
[ERROR] Python 3.9 installation failed. Cannot continue setup.
Check that your Ubuntu version is supported by the deadsnakes PPA.
See https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa for supported versions.
```

7. Source your environment. You should see a `(drone-venv)` virtual environment appear in your prompt.

```sh
# Windows / Linux
source ~/.bashrc

# Mac
source ~/.zshrc
```

8. Test the custom `drone` command.

```sh
drone test
```

```sh
drone tool set up successfully!
  DRONE_ABSOLUTE_PATH: /home/user/uav-neo-installer/drone-student
  DRONE_IP: 127.0.0.1
  DRONE_TEAM: student
```

9. Open the simulator.

```sh
drone cd && cd ../../UAVNeo-Simulator

# Open file in file explorer
explorer.exe .    # Windows
open .            # Mac
nautilus .        # Linux

# Find the executable called UAVSim and open it.
UAVSim.exe        # Windows
UAVSim.app        # Mac
UAVSim.x86_64     # Linux
```

10. In the terminal, run `demo.py` to check that the setup was successful.

```sh
drone cd

drone sim demo.py

# Hit the Enter key in the simulator.
# The "A" button (1 key on computer) prints a statement to the terminal (Sim -> Python check)
# The "B" button (2 key on computer) launches the drone, flies it forward and to the right, then lands the drone (Python <-> Sim check)
```

---

## Updating

To update your labs, library, or simulator after initial setup:

```sh
bash uav-neo-installer/drone-student/scripts/update.sh
```

You will be prompted to select which component to update (labs, library, or sim). A post-update check will verify everything is working correctly.

**Note:** Updating labs will replace your existing labs folder. Back up any work before running the update.

---

## Troubleshooting

### Setup log files

Setup and update logs are saved to `drone-student/scripts/.logs/`. Each run creates a timestamped log file (e.g., `setup_2026-03-29_18-41-11.log`). Share this file with your instructor if you encounter issues.

### Simulator won't connect (Windows/WSL2)

If the simulator connects when offline but not when connected to the internet, you need to configure the Windows Firewall. Open **PowerShell as Administrator** and run:

```powershell
New-NetFirewallRule -DisplayName "WSL2 UAVNeo Simulator" -Direction Inbound -InterfaceAlias "vEthernet (WSL)" -Action Allow -Protocol UDP -LocalPort 5064-5065
```

### Python 3.9 fails to install

The setup script uses the [deadsnakes PPA](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa) to install Python 3.9. This PPA supports Ubuntu 22.04 (jammy) and 24.04 (noble). If you are on a different version, you may need to install Python 3.9 manually.

### Virtual environment issues

If the virtual environment fails to activate or dependencies are missing, try recreating it:

```sh
cd uav-neo-installer
python3.9 -m venv drone-venv
source drone-venv/bin/activate
pip install --upgrade pip
pip install -r drone-student/scripts/requirements.txt
```

### drone command not found

Make sure you have sourced your shell configuration:

```sh
# Windows / Linux
source ~/.bashrc

# Mac
source ~/.zshrc
```

---
