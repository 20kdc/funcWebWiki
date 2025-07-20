local mimetype = wikiExtToMime(wikiRequestExtension)
if mimetype then
	SetHeader("Content-Type", mimetype)
end
Write(Slurp(wikiRequestPath))
