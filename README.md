# AutoToggleTouchpad
A set of AutoHotkey (aka "AHK") scripts to enable automatic toggling of any laptop's or laptop-like tablet's (with detachable keyboard+touchpad) built-in touchpad, which on device change detection, is disabled if another external mouse or pointing device is detected (connected), or enabled if no other mouse/pointing device is detected (removed).

* Server script meant to be run with administrator rights, best launched on Windows start-up using Task Manager.
  * On Windows hardware change events, script will check through all pointing devices (i.e. class ```Win32_PointingDevice```), and disable the configured touchpad; other devices to be ignored from consideration may also be specified (as comma-separate list).

* Client script can be run on user startup/login and has a system tray icon to "**pause**", "**unpause**" the toggling logic or send a "**shutdown**" command to the server script (which then terminates the server).
  * **Pausing** functionality will first _enable_ the "internal" trackpad, and **resuming** functionality will go through the standard checks/logic as if a device was connected/disconnected.

* "Client" to "Server" communications is via text file (i.e. client AHK process must have write functionality to configured directory and file, server AHK process must have read and write functionality to configured directory and file.

<img width="374" height="158" alt="image" src="https://github.com/user-attachments/assets/31e6a9c6-cb02-491b-ad62-420d98dbce48" />

# Instructions

* edit both files to:
  * specify the hardware IDs of the internal touchpad as well as any HIDs to be excluded "utility directory", log file and "command" file
    * ```ToogleTouchpadServer.ahk```:
      * TargetTouchpadID
      * ExcludedDevices[]
      * SharedFolder
      * CommandFile
      * LogFile
    * ```ToggleTouchpadClient.ahk```:
      * CommandFile
* create or use directory as configured
* create Task Manager "Windows Startup Task"

  <img width="632" height="480" alt="image" src="https://github.com/user-attachments/assets/3fb5d51a-2794-4c33-9075-9c754f9ed537" />
  <img width="632" height="480" alt="image" src="https://github.com/user-attachments/assets/7fa0ca68-9f95-40e2-9c27-715f6c95550a" />
  <img width="632" height="480" alt="image" src="https://github.com/user-attachments/assets/9a86b92b-f6f7-407a-96f1-9221bae6cf5f" />
  <img width="632" height="480" alt="image" src="https://github.com/user-attachments/assets/ec94facf-d847-435a-9b0f-58340d5a7d7a" />
  <img width="632" height="480" alt="image" src="https://github.com/user-attachments/assets/75a54c8f-ea27-4800-baab-d38e4f857810" />

* create a startup shortcut to the client script in user's startup folder (e.g. enter "```shell:startup```" in Windows Explorer's address bar)
