#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
Persistent

; --- CONFIGURATION ---
global TargetTouchpadID := "HID\VID_258A&PID_001E&MI_01&COL01\9&1BE53A5C&0&0000"
global ExcludedDevices := [
    "HID\VID_046D&PID_C548&MI_01&COL01\B&1DAF790C&0&0000" ; You can add more entries separated by commas
]
global SharedFolder := "C:\TouchpadAutoToggle"
global CommandFile := SharedFolder . "\command.txt"
global LogFile := SharedFolder . "\server_log.txt"
; ---------------------

global IsPaused := false

if !DirExist(SharedFolder) {
    try DirCreate(SharedFolder)
}

; Initial test write to confirm script execution immediately
WriteLog("--- SERVER DAEMON STARTING ---")

; Ensure touchpad is enabled initially
EnableTouchpad()

; Set up Windows Directory Change Notification [source: 8, 12]
global FILE_NOTIFY_CHANGE_FILE_NAME := 0x00000001
global changeHandle := DllCall("FindFirstChangeNotification", "Str", SharedFolder, "Int", 0, "UInt", FILE_NOTIFY_CHANGE_FILE_NAME, "Ptr")

if (changeHandle = -1) {
    WriteLog("CRITICAL ERROR: Failed to create FindFirstChangeNotification handle.")
    ExitApp()
} else {
    WriteLog("SUCCESS: Created FindFirstChangeNotification handle successfully.")
}

; Listen for Hardware Plug/Unplug events (WM_DEVICECHANGE)
OnMessage(0x0219, OnHardwareChange)

; Initial mouse scan
CheckMice()

; Start event dispatcher loop
SetTimer(EventDispatcher, -1)

OnHardwareChange(wParam, lParam, msg, hwnd) {
    if (wParam = 7) {
        WriteLog("EVENT: WM_DEVICECHANGE detected. Re-scanning mice in 1 second...")
        SetTimer(CheckMice, -1000)
    }
}

EventDispatcher() {
    global changeHandle, CommandFile, IsPaused, LogFile
    
    handleBuf := Buffer(A_PtrSize, 0)
    NumPut("Ptr", changeHandle, handleBuf, 0)

    Loop {
        ; Suspends CPU until folder changes OR a Windows message arrives
        res := DllCall("MsgWaitForMultipleObjects", "UInt", 1, "Ptr", handleBuf, "Int", 0, "UInt", 0xFFFFFFFF, "UInt", 0x04FF)
        
        ; res = 0: Folder change detected (command.txt created/deleted) [source: 8, 12]
        if (res = 0) {
            WriteLog("INTERRUPT: Directory change detected.")
            
            if FileExist(CommandFile) {
                try {
                    cmd := Trim(FileRead(CommandFile))
                    WriteLog("FILE: Successfully read command: [" . cmd . "]")
                    
                    FileDelete(CommandFile)
                    WriteLog("FILE: Deleted command.txt")
                    
                    if (cmd = "PAUSE") {
                        IsPaused := true
                        WriteLog("ACTION: PAUSED. Forcing touchpad ON.")
                        EnableTouchpad()
                    } else if (cmd = "RESUME") {
                        IsPaused := false
                        WriteLog("ACTION: RESUMED. Checking mice...")
                        CheckMice()
                    } else if (cmd = "EXIT") {
                        WriteLog("ACTION: EXIT. Re-enabling touchpad and quitting.")
                        EnableTouchpad()
                        DllCall("FindCloseChangeNotification", "Ptr", changeHandle)
                        WriteLog("--- SERVER DAEMON EXITED ---")
                        ExitApp()
                    }
                } catch as err {
                    WriteLog("ERROR: Failed processing command.txt: " . err.Message)
                }
            }
            
            ; Re-arm change notification
            DllCall("FindNextChangeNotification", "Ptr", changeHandle)
        }
        ; res = 1: Message received (hardware change, etc.)
        else if (res = 1) {
            Sleep(-1)
        }
    }
}

CheckMice() {
    global TargetTouchpadID, IsPaused
    if (IsPaused) {
        WriteLog("SCAN: Skipped because server is paused.")
        return
    }

    externalMouseFound := false
    deviceSummary := ""
    
    for dev in ComObjGet("winmgmts:").ExecQuery("Select PNPDeviceID from Win32_PointingDevice") {
        pnpId := dev.PNPDeviceID
        deviceSummary .= "`n  - " . pnpId
        
        ; 1. Skip the default internal trackpad
        if (pnpId = TargetTouchpadID)
            continue
            
        ; 2. Skip legacy ACPI controllers or Virtual Software mice
        if InStr(pnpId, "ACPI") or InStr(pnpId, "VIRTUAL")
            continue
            
        ; 3. NEW: Check against the custom array of excluded hardware IDs
        isExplicitlyExcluded := false
        for excludedId in ExcludedDevices {
            if InStr(pnpId, excludedId) {
                isExplicitlyExcluded := true
                break
            }
        }
        
        if (isExplicitlyExcluded) {
            deviceSummary .= " [EXCLUDED]"
            continue
        }
        
        ; If it survives all filters, it is a valid external mouse triggering a toggle
        externalMouseFound := true
    }

    WriteLog("SCAN: Pointing devices detected:" . deviceSummary)

    if (externalMouseFound) {
        WriteLog("SCAN: External mouse found. Disabling trackpad: " . TargetTouchpadID)
        RunWait('pnputil.exe /disable-device "' . TargetTouchpadID . '"', , "Hide")
    } else {
        WriteLog("SCAN: No external mouse found. Enabling trackpad.")
        EnableTouchpad()
    }
}

EnableTouchpad() {
    global TargetTouchpadID
    WriteLog("HARDWARE: Enabling device: " . TargetTouchpadID)
    RunWait('pnputil.exe /enable-device "' . TargetTouchpadID . '"', , "Hide")
}

WriteLog(text) {
    global LogFile
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    try {
        FileAppend(timestamp . " | " . text . "`r`n", LogFile, "UTF-8")
    }
}
