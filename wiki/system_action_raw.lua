local requestPath, requestExt = ...
-- Just return the raw asset.
local mimetype = wikiExtToMime(requestExt)
local length, stamp = wikiReadStamp(requestPath)

-- doRead supersedes doLength; doRead is set to false for HEAD-like situations
-- doLength is set to false if we shouldn't even suggest Content-Length (a content length is inappropriate for this request method / response type combo)
local doRead = true
local doLength = true

local method = GetMethod()
if method == "HEAD" then
	doRead = false
end

if not length then
	SetStatus(404)
else
	if stamp and stamp ~= "" then
		-- Generate ETags for caching of images/etc. as these are large resources
		local etag = "W/\"" .. EncodeHex(Md5(requestPath .. "_".. stamp)) .. "\""
		if GetHeader("If-None-Match") == etag then
			SetStatus(304)
			doLength = false
			doRead = false
		end
		SetHeader("ETag", etag)
	end
	if mimetype then
		SetHeader("Content-Type", mimetype)
	end

	if doRead then
		Write(wikiRead(requestPath))
	elseif doLength then
		SetHeader("Content-Length", tostring(length))
	end
end
