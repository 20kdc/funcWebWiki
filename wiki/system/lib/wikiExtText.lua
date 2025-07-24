-- Returns true if a file extension is 'textish'.
-- Textish files can be edited in the text editor.
return function (ext)
	return (wikiExtToMime(ext) or ""):sub(1, 5) == "text/"
end
