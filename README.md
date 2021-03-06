# pahkit
An AutoHotKey gui tool that allows flexible command management to supply more ergonomic options for Windows.
The most common use case is to simply map your common browser bookmarks and applications so that they can easily be launched without navigating using the mouse.
This was originally developed to assist with ergonomics and efficiency.

Intended pronunciation: pocket

Written by Cameron Dinopoulos
2018-09-15

## Getting Started
- Install AutoHotKey for Windows
- Download [pahkit](https://github.com/tungstn/pahkit)
- Run the gui.ahk file from this project (consider creating a central startup.ahk script and simply using Include instead)
- Use \<win\>+\<space\> to open the gui
- Modify or create your own guicommands.ahk file to configure the commands


## Configuration

| variable | description | default | options |
|:--------:|:-----------:|:-------:|:-------:|
| pathHelpFile | Path to the pahkit help file.  Note that this will be relative to the working directory of the containing script | "help.html" | - |
| pathGuiCommands | Path to the user's guicommands file.  Note that this will be relative to the working directory of the containing script | "guicommands.txt" | - |
| autocompleteCommand | Allows for the gui to immediately run the single command that matches the input text, if more than one command matches the input, normal processing applies.  "off" to turn this setting off, "submit" to allow autocomplete of the single matching command when you press enter (submit the form), "change" to allow autocomplete of the single matching command as soon as only 1 command remains matched | submit | off, submit, change |

