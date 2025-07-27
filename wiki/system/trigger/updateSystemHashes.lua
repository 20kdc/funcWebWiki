-- Creates/updates the <system/hashes.json> file.
-- _Beware!_ This file exists to set a 'reference point' for <special/systemPages>.
local res = {}
for _, v in ipairs(wikiPathList("system/")) do
	if v:sub(1, 13) ~= "system/cache/" and v ~= "system/hashes.json" and v ~= "system/newHashes.json" then
        res[v] = EncodeHex(Md5(wikiRead(v)))
	end
end
wikiWrite("system/hashes.json", EncodeJson(res, {pretty = true}))
