#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force


gui_init() {
	static _ := gui_init() ; force auto execute this script regardless of where it is imported

	; keep track of the state of the GUI
	global gui_state
	gui_state = closed

	return
}


#Space::
gui_create:
	global gui_state
    if gui_state != closed
    {
        ; If the GUI is already open, close it.
        gui_destroy()
        return
    }

    gui_state = main

    Gui, Margin, 4, 4
    Gui, +AlwaysOnTop -SysMenu +ToolWindow -caption +Border
    Gui, Font, s11, Segoe UI	
	
	
    Gui, Add, Text, vgui_main_title, Search...
	
	
    Gui, Font, s10, Segoe UI
    Gui, Add, Edit, vEditText gInputChanged
	
    Gui, Add, Link, , <a href="help.html">Help</a>
	
    Gui, Show,, myGUI
    return


; Automatically triggered on Escape key:
GuiEscape:
    gui_destroy()
    return
	
	
; gui_destroy: Destroy the GUI after use.
#WinActivateForce
gui_destroy() {
    global gui_state

    gui_state = closed

    ; Hide GUI
    Gui, Destroy

    ; Bring focus back to another window found on the desktop
    WinActivate
	
	return
}
	

; The callback function when the text changes in the input field.
InputChanged:
	Gui, Submit, NoHide
	ProcessInput(EditText)
	return


ProcessInput(input) {
    
	if input = rel%A_Space% 
	{
		gui_destroy()
		Reload
	}
	
	if av = exit%A_Space%
	{
		gui_destroy()
		ExitApp
	}
	
	
	for k, v in LoadCommands()
	{
		if (input = k . A_Space) {
			gui_destroy()
			Run % v
		}
	}
	
    return
}


LoadCommands() {
	commands := []
	loop, read, guicommands.txt
	{
		rawline := A_LoopReadLine
		
		; ignore commented lines starting with ";"
		if (SubStr(rawline, 1, 1) = ";") {
			continue
		}
		
		; ignore whitespace lines starting with ""
		if (rawline = "") {
			continue
		}
		
		line := StrSplit(A_LoopReadLine, ",")
		commands[line[1]] := line[2]
	}
	return commands
}


