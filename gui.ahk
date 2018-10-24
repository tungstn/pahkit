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
	
	global allCommands
	allCommands := GetAllCommandsAsListBox()

	global bAllowQuickCommandAfterSingleRecordMatch ; allows for the gui to immediately run the single command that matches the input text, if more than one command matches the input, normal processing applies
	bAllowQuickCommandAfterSingleRecordMatch := false
	
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
    Gui, Font, s11, Consolas	
	
	
    Gui, Add, Text, vgui_main_title, Search...
	
	; actual text input box
    Gui, Font, s10, Consolas
    Gui, Add, Edit, vEditText gInputChanged
	
	; list box to list filtered command options
	Gui, Add, ListBox, vListBoxSelection gListBoxSubmitted r7, %allCommands%
	GuiControl, Choose, ListBoxSelection, 1
	
	; link to help document
    Gui, Add, Link, , <a href="help.html">Help</a>
	
	Gui, Add, Button, gButtonReload x+10, &Reload
	Gui, Add, Button, gButtonQuit x+10, &Quit
	
	; hidden submit button to capture the <enter> key and submit the form
	Gui, Add, Button, Default w0 h0 gButtonSubmittedWithEnter, OK
	
    Gui, Show,, myGUI
    return


; Automatically triggered on Escape key:
GuiEscape:
    gui_destroy()
    return
	
	
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

ListBoxSubmitted:	
	if(A_GuiEvent != "DoubleClick") {
		return
	}
	
	; submit gui so that listboxselection variable is set
	Gui, Submit, NoHide	
	ProcessInput(ListBoxSelection, "") ; no delimiter since we're just passing the exact command
	
	return



ButtonReload:
	gui_destroy()
	Reload
	return

ButtonQuit:
	gui_destroy()
	ExitApp
	return
	
ButtonSubmittedWithEnter:
	Gui, Submit, NoHide
	ProcessInput(EditText, "")	
	return

; The callback function when the text changes in the input field.
InputChanged:
	Gui, Submit, NoHide
	ProcessInput(EditText, A_Space)
	
	filteredCommands := GetFilteredCommandsAsListBox(EditText)
	GuiControl, -Redraw, ListBoxSelection		; To improve performance, don't redraw the list box until all items have been added.
	GuiControl, , ListBoxSelection, |%filteredCommands%	; use a delimiter in front to clear all current contents before readding
	GuiControl, +Redraw, ListBoxSelection
	GuiControl, Choose, ListBoxSelection, 1

	return


ProcessInput(input, delimiter = " ") {
    
	if input = rel%delimiter%
	{
		gui_destroy()
		Reload
		return
	}
	
	if av = exit%delimiter%
	{
		gui_destroy()
		ExitApp
		return
	}
	
	
	for k, v in LoadCommands()
	{
		if (input = k . delimiter) {
			gui_destroy()
			Run % v
			return
		}
	}
	
	; if no matches have been found so far, but only one selection exists in the filtered commands, run that command
	; this saves frustration and keystrokes when you know what you have to type
	global bAllowQuickCommandAfterSingleRecordMatch
	if (bAllowQuickCommandAfterSingleRecordMatch = true)
	{
		filteredCommands := GetFilteredCommandsAsListBox(input)
		matchesAsArray := StrSplit(filteredCommands, "|")
		if (matchesAsArray.Length() = 2) {
			;msgbox % "first match: " . StrSplit(filteredCommands, "|")[1]
			firstMatchKey := matchesAsArray[1]
			gui_destroy()
			Run % LoadCommands()[firstMatchKey]
			return
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

GetAllCommandsAsListBox() {
	return GetCommandsAsListBox(LoadCommands())
}

GetFilteredCommandsAsListBox(partialCommand) {
	commands := LoadCommands()
	
	filtered := []
	for k, v in commands
	{
		if (RegExMatch(k, partialCommand) > 0) {
			filtered[k] := v
		}
	}
	
	return GetCommandsAsListBox(filtered)
}

GetCommandsAsListBox(commands) {
	listStr := ""
	for k, v in commands
	{
		listStr := listStr . k . "|"
	}
	return listStr
}
