-- Just return the raw asset.
local mimetype = wikiExtToMime(wikiRequestExt)
if mimetype then
	SetHeader("Content-Type", mimetype)
end
Write(Slurp(wikiRequestPath))
