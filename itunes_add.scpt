#!/usr/bin/env osascript
on run argv
	set v_name to item 1 of argv
	set v_file to POSIX file v_name
	tell application "iTunes"
		add v_file
	end tell
	return
end run
