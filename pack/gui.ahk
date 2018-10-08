#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force

SetCapsLockState, AlwaysOff

; #InstallKeybdHook

;-------------------------------------------------------
; AUTO EXECUTE SECTION FOR INCLUDED SCRIPTS
; Scripts being included need to have their auto execute
; section in a function or subroutine which is then
; executed below.
;-------------------------------------------------------

gui_control_options := "xm w220 " . cForeground . " -E0x200"
; -E0x200 removes border around Edit controls

; Initialize variable to keep track of the state of the GUI
gui_state = closed

;-------------------------------------------------------
; END AUTO EXECUTE SECTION
return
;-------------------------------------------------------

;-------------------------------------------------------------------------------
; LAUNCH GUI
;-------------------------------------------------------------------------------
#Space::
gui_spawn:
    if gui_state != closed
    {
        ; If the GUI is already open, close it.
        gui_destroy()
        return
    }

    gui_state = main

    Gui, Margin, 16, 16
    Gui, Color, 1d1f21, 282a2e
    Gui, +AlwaysOnTop -SysMenu +ToolWindow -caption +Border
    Gui, Font, s11, Segoe UI
    Gui, Add, Text, %gui_control_options% vgui_main_title, Search...
    Gui, Font, s10, Segoe UI
    Gui, Add, Edit, %gui_control_options% vEditText gInputChanged
    Gui, Show,, myGUI
    return

;-------------------------------------------------------------------------------
; GUI FUNCTIONS AND SUBROUTINES
;-------------------------------------------------------------------------------
; Automatically triggered on Escape key:
GuiEscape:
    gui_destroy()
    return

; The callback function when the text changes in the input field.
InputChanged:
    Gui, Submit, NoHide
    
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
	
	; MsgBox % join(inputWords) ; debug the current input words
	
	keywordsList := [new ExecuteKeyword(["note"], "Notepad"), new ExecuteKeyword(["g", "github"], "https://www.google.com")]
	;MsgBox % keywordsList.Length()
	
	lastMatchingObject = ; null
	numKeywordMatches = 0
	for j, keywordObj in keywordsList 
	{
		; MsgBox % join(keywordObj.keywords)
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
				;MsgBox % "'" word "'" keyword "'" wordsFound
			}
		}
		;MsgBox % keywordObj.path wordsFound
		
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
