local requestPath, requestExt = ...
-- Just return the raw asset.
local mimetype = wikiExtToMime(requestExt)
if mimetype then
	SetHeader("Content-Type", mimetype)
end
Write(Slurp(requestPath))
