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
}
	

; The callback function when the text changes in the input field.
InputChanged:
	Gui, Submit, NoHide
	ProcessInput(EditText)
	return


ProcessInput(input) {
    
	if EditText = rel%A_Space% 
	{
		gui_destroy()
		Reload
	}
	
	if EditText = exit%A_Space%
	{
		gui_destroy()
		ExitApp
	}
	
	
	loop, read, guicommands.txt
	{
		command := StrSplit(A_LoopReadLine, ",")
		
		if (EditText = command[1] . A_Space) {
			gui_destroy()
			Run % command[2]
		}
	}
	
	
	inputWords := StrSplit(EditText, A_Space)
	
	keywordsList := [new ExecuteKeyword(["note"], "Notepad"), new ExecuteKeyword(["g", "github"], "https://www.google.com")]
	
	lastMatchingObject = ; null
	numKeywordMatches = 0
	for j, keywordObj in keywordsList 
	{
		allWordsFound = 0
		wordsFound = 0
		for i, word in inputWords
		{
			for k, keyword in keywordObj.keywords
			{
				; track to see if we match all words expected for a given keyword object
				if word = %keyword%
				{
					wordsFound := %wordsFound% + 1
				}
			}
		}
		
		len := inputWords.Length()
		; track how many different keyword objects match all the words
		if wordsFound = %len%
		{
			numKeywordMatches = numKeywordMatches + 1
			lastMatchingObject = keywordObj
		}
	}
	
	if numKeywordMatches = 1 
	{
		Run %lastMatchingObject%.path
	}
	
    return
}


class ExecuteKeyword
{
	;keywords := []
	path := ""
	args := ""
	__New(keywords, path, args := "")
	{
		this.keywords := keywords ; ["test"]
		this.path := path
		this.args := args
	}
}



join( strArray )
{
  s := ""
  for i,v in strArray
    s .= ", " . v
  return substr(s, 3)
}
