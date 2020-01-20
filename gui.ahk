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
	
	global pathHelpFile 
	pathHelpFile := "help.html" ; note that this will be relative to the working directory of the containing script
	
	global pathGuiCommands
	pathGuiCommands := "guicommands.txt" ; note that this will be relative to the working directory of the containing script
	
	global allCommands
	allCommands := GetAllCommandsAsListBox()

	global autocompleteCommand ; allows for the gui to immediately run the single command that matches the input text, if more than one command matches the input, normal processing applies
		; "off" 	to turn this setting off
		; "submit" 	to allow autocomplete of the single matching command when you press enter (submit the form)
		; "change" 	to allow autocomplete of the single matching command as soon as only 1 command remains matched
	autocompleteCommand := "submit"

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

    Gui, Margin, 8, 8
    Gui, +AlwaysOnTop +SysMenu +ToolWindow -caption +Border
    Gui, Font, s11, Consolas
	; Gui, Color, aaeecc
	
	
    Gui, Add, Text, vgui_main_title, Search...
	
	; actual text input box
    Gui, Font, s10, Consolas
    Gui, Add, Edit, vEditText gInputChanged
	
	; list box to list filtered command options
	Gui, Add, ListBox, vListBoxSelection gListBoxSubmitted r7, %allCommands%
	GuiControl, Choose, ListBoxSelection, 1
	
	; link to help document
    Gui, Add, Link, , <a href="%pathHelpFile%">Help</a>
	
	Gui, Add, Button, gButtonReload x+10, &Reload
	Gui, Add, Button, gButtonQuit x+10, &Quit
	
	; hidden submit button to capture the <enter> key and submit the form
	Gui, Add, Button, Default w0 h0 gButtonSubmittedWithEnter, OK
	
	; Show a default status bar at the bottom of the GUI.  This is used to show how many commands are loaded.
	Gui, Add, StatusBar,, Config: %pathGuiCommands%

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
	matchFound := ProcessInput(EditText, "")	
	
		
	; If no matches have been found so far, but only one selection exists in the filtered commands, run that command
	; this saves frustration and keystrokes when you know what you have to type
	global autocompleteCommand
	if (autocompleteCommand = "submit")
	{
		if (!matchFound) {
			AutoCompleteCommand(EditText)
		}
	}
	return

; The callback function when the text changes in the input field.
InputChanged:
	Gui, Submit, NoHide

	; Update the list box to only show the command shortcuts that match the text entered so far.
	filteredCommands := GetFilteredCommandsAsListBox(EditText)
	GuiControl, -Redraw, ListBoxSelection		; To improve performance, don't redraw the list box until all items have been added.
	GuiControl, , ListBoxSelection, |%filteredCommands%	; use a delimiter in front to clear all current contents before readding
	GuiControl, +Redraw, ListBoxSelection
	GuiControl, Choose, ListBoxSelection, 1
	
	matchFound := ProcessInput(EditText, A_Space)

	; If no matches have been found so far, but only one selection exists in the filtered commands, run that command
	; this saves frustration and keystrokes when you know what you have to type
	global autocompleteCommand
	if (autocompleteCommand = "change")
	{
		if (!matchFound) {
			AutoCompleteCommand(EditText)
		}
	}

	
	; Update the status bar (at the bottom) to show the number of matches out of the total sum of commands
	matchCount := GetFilteredCommandsAsArray(EditText).Count()
	allCount := LoadCommands().Count()
	SB_SetText(matchCount . "/" . allCount . " commands match")
	
	return

; Process a given set of input (text) and evaluate whether or not it matches a given command shortcut.
; Special "command shortcuts" are hardcoded for "rel" and "exit" which will reload the script and close the 
; script, respectively.
ProcessInput(input, delimiter = " ") {
    
	if input = rel%delimiter%
	{
		gui_destroy()
		Reload
		return true
	}
	
	if av = exit%delimiter%
	{
		gui_destroy()
		ExitApp
		return true
	}
	
	
	for k, v in LoadCommands()
	{
		if (input = k . delimiter) {
			gui_destroy()
			Run % v
			return true
		}
	}
	
    return false
}


; If no matches have been found so far, but only one selection exists in the filtered commands, run that command
; this saves frustration and keystrokes when you know what you have to type.
AutoCompleteCommand(input) {
		
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

; Reads commands from a configuration file.
; Commands are of the following grammar: ([^,]),(.*)\n where the first capture is the "command shortcut", and the second capture
; is the actual executable "command".
; Commands can be nested AHK scripts/syntax, or executable syscalls.
; LoadCommands().Length() will return the total number of valid commands pairs.
LoadCommands() {
	global pathGuiCommands

	commands := []
	loop, read, %pathGuiCommands%
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

; Returns a string where all valid commands are delimited by a "|" for all commands found in the config file.
GetAllCommandsAsListBox() {
	return GetCommandsAsListBox(LoadCommands())
}

; Returns a key value map/Array containing only those commands which match a given partialCommand
GetFilteredCommandsAsArray(partialCommand) {

	commands := LoadCommands()
	
	filtered := []
	for k, v in commands
	{
		if (RegExMatch(k, partialCommand) > 0) {
			filtered[k] := v
		}
	}
	return filtered
}

; Returns a delimited string (|) containing only those commands which match a given partialCommand
GetFilteredCommandsAsListBox(partialCommand) {
	
	return GetCommandsAsListBox(GetFilteredCommandsAsArray(partialCommand))
}

; Returns a string where all valid commands are delimited by a "|".
GetCommandsAsListBox(commands) {
	listStr := ""
	for k, v in commands
	{
		listStr := listStr . k . "|"
	}
	return listStr
}
