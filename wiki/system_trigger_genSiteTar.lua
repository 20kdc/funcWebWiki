local function dumpTarFile(name, data)
	name = name:sub(1, 100)
	name = name .. ("\x00"):rep(100 - #name)
	name = name .. string.format("%07o", 420) .. "\x00" -- mode
	name = name .. string.format("%07o", 1000) .. "\x00" -- user
	name = name .. string.format("%07o", 1000) .. "\x00" -- group
	name = name .. string.format("%011o", #data) .. "\x00"
	name = name .. string.format("%011o", 0) .. "\x00"
	name = name .. "        "
	name = name .. "\x00"
	name = name .. ("\x00"):rep(512 - #name)
	-- calculate checksum...
	local checksum = 0
	for i = 1, #name do
		checksum = (checksum + name:byte(i)) % 262144
	end
	-- patch in
	name = name:sub(1, 148) .. string.format("%06o", checksum) .. "\x00 " .. name:sub(157)
	Write(name)
	Write(data)
	local integral = (#data) % 512
	if integral ~= 0 then
		Write(("\x00"):rep(512 - integral))
	end
end

SetHeader("Content-Type", "application/octet-stream")

if false then
	-- debug TAR write code
	dumpTarFile("test", "abc123\n")
else
	local preferredIndex = wikiResolvePage(wikiDefaultPage)
	-- actually generate site
	for _, v in ipairs(wikiPathList()) do
		-- re-virtualize names to avoid needing to handle relative traversal for file:
		local vAdjName = v:gsub("/", "_")
		dumpTarFile(vAdjName, wikiRead(v))
		local template = WikiTemplate("system/index/frame", { path = v })
		local html = wikiAST.renderToString(template, { renderType = "renderHtml", disableErrorIsolation = true, staticSite = true, absoluteBase = "" })
		dumpTarFile(vAdjName .. ".html", html)
		if v == preferredIndex then
			dumpTarFile("index.html", html)
		end
	end
end

Write(("\x00"):rep(1024 + 0x2000))
