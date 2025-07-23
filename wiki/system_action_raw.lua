local requestPath, requestExt = ...
-- Just return the raw asset.
local mimetype = wikiExtToMime(requestExt)
local length, stamp = wikiReadStamp(requestPath)

-- Redbean does a lot of convenient things, but it also takes control of stuff like Content-Length and range handling.
-- To be clear, _in a sense,_ this is a good thing.
-- However, _in this specific code,_ since there's no 'serve from FS' primitive, we must invent one.
-- (While using assets for everything sounds nice, the need to list files and cleanly switch between zip and fs content precluded this.)

-- This flag controls if we're going to `Write` a request body that is, for this request, semantically equivalent to the file.
-- If the body is full of zero bytes or not has nothing to do with anything.
local doRead = true

if not length then
	SetStatus(404)
else
	if stamp and stamp ~= "" then
		-- Generate ETags for caching of images/etc. as these are large resources
		local etag = "W/\"" .. EncodeHex(Md5(requestPath .. "_".. stamp)) .. "\""
		if GetHeader("If-None-Match") == etag then
			SetStatus(304)
			doRead = false
		end
		SetHeader("ETag", etag)
	end
	if mimetype then
		SetHeader("Content-Type", mimetype)
	end

	if doRead then
		if GetMethod() ~= "HEAD" then
			Write(wikiRead(requestPath))
		else
			-- We don't want to waste time actually reading the contents for a HEAD request, so we'll just fake it with zero bytes.
			-- The code that was previously here and didn't work is kept here as a teaching aid.
			-- Test with `curl -I http://127.0.0.1:8080/test?action=raw` and observe how the header is ignored.

			-- SetHeader("Content-Length", tostring(length)) -- bad
			Write(string.rep("\x00", length)) -- good
		end
	end
end
