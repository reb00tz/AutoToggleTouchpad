#Requires AutoHotkey v2.0
#SingleInstance Off

; Check for a running instance within the current session first
DetectHiddenWindows(True)
myPID := ProcessExist() ; Get current running PID

; Scan all native AHK windows to find an exact matching file path that ISN'T this PID
duplicateHwnd := 0
for hwnd in WinGetList(A_ScriptFullPath " - AutoHotkey ahk_class AutoHotkey") {
    if (WinGetPID(hwnd) != myPID) {
        duplicateHwnd := hwnd
        break
    }
}

if (duplicateHwnd) {
;    MsgBox("Debug: A separate instance of this script is already running!`n" 
;         . "Current instance HWND: " . Format("0x{:x}", A_ScriptHwnd) . "`n"
;         . "Background instance HWND: " . Format("0x{:x}", duplicateHwnd) . "`nExiting now.")
    ExitApp()
}

Persistent() ; Forces the client to stay running in the background! 

global CommandFile := "C:\TouchpadAutoToggle\command.txt"
global IsActive := true

; Force the Tray Icon to load immediately
A_IconTip := "Touchpad Automator: Running"
A_TrayMenu.Delete()
A_TrayMenu.Add("Pause Touchpad Auto Toggle", ToggleState)
A_TrayMenu.Add("Shutdown && Exit", CloseAll)
A_TrayMenu.Default := "Pause Touchpad Auto Toggle"

; Brief visual confirmation that the client loader did not crash
TrayTip("Touchpad Auto Toggle", "Client active and loaded.", 1)
SetTimer(() => TrayTip(), -1500)

ToggleState(*) {
    global IsActive
    if (IsActive) {
        if SendCommand("PAUSE") {
            IsActive := false
            A_TrayMenu.Rename("Pause Touchpad Auto Toggle", "Resume Touchpad Auto Toggle")
            A_IconTip := "Touchpad Auto Toggle: PAUSED"
            TrayTip("Touchpad Auto Toggle", "Touchpad Auto Toggle Paused (Touchpad Forced ON)", 1)
        }
    } else {
        if SendCommand("RESUME") {
            IsActive := true
            A_TrayMenu.Rename("Resume Touchpad Auto Toggle", "Pause Touchpad Auto Toggle")
            A_IconTip := "Touchpad Auto Toggle: Running"
            TrayTip("Touchpad Auto Toggle", "Touchpad Auto Toggle Resumed", 1)
        }
    }
    SetTimer(() => TrayTip(), -1500)
}

CloseAll(*) {
    SendCommand("EXIT")
    ExitApp()
}

SendCommand(cmd) {
    global CommandFile
    try {
        ; Write command to the shared text file
        if FileExist(CommandFile)
            FileDelete(CommandFile)
        FileAppend(cmd, CommandFile)
        return true
    } catch {
        TrayTip("Touchpad Auto Toggle Error", "Could not write to shared directory.", 2)
        SetTimer(() => TrayTip(), -3000)
        return false
    }
}
