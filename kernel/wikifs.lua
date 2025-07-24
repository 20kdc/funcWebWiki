-- Internal detail of funcWebWiki-kernel. The APIs directly exposed by this file can break at any time. --

-- Implements the path parsing rules of funcWebWiki.

-- allowNoExt is useful for page canonicalization before we know what extension to look for.
local function pathParse(path, allowNoExt)
	if path:sub(1, 1) == "." then
		return nil, "hidden"
	end
	local res = {}
	local last = nil
	for v in string.gmatch(path, "[^/]+") do
		if last then
			if last:find(".", 1, true) then
				return nil, "directories cannot have extensions"
			end
		end
		if v == "." or v == ".." then
			return nil, "traversal components"
		end
		if v:find("\\") then
			return nil, "traversal"
		end
		table.insert(res, v)
		last = v
	end
	if #res == 0 then
		-- this error message is relied upon to resolve all empty paths
		return nil, "empty"
	end
	if not (allowNoExt or last:find(".", 1, true)) then
		-- this error message is relied upon to fixup missing-extension paths
		return nil, "no extension"
	end
	return res
end

local function pathUnparse(wp)
	local path = ""
	for k, v in ipairs(wp) do
		if k ~= 1 then
			path = path .. "/"
		end
		path = path .. v
	end
	return path
end

local function pathToDisk(base, path)
	local parsed, err = pathParse(path)
	if not parsed then
		return nil, ("invalid path (" .. tostring(err) .. "): " .. path)
	end
	local path = base
	for k, v in ipairs(parsed) do
		if k ~= 1 then
			path = path .. "/"
		end
		path = path .. v
	end
	return path
end

local function makeFSReadOnly(fs)
	fs.readOnly = true
	fs.delete = function () return nil, "wiki read-only" end
	fs.write = fs.delete
end

return {
	pathParse = pathParse,
	pathUnparse = pathUnparse,
	makeFSReadOnly = makeFSReadOnly,
	newAssetFS = function (base)
		local fs = { readOnly = false }

		function fs.read(path)
			local path2, err = pathToDisk(base, path)
			if not path2 then
				return nil, err
			end
			-- Redbean will be loud if we don't check, and we may need a deletion mechanism in future anyway.
			-- So empty files will act a little buggy.
			if (GetAssetSize(path2) or 0) <= 0 then
				return nil, "does not exist"
			end
			-- Continue.
			local a = LoadAsset(path2)
			if not a then
				return nil, "does not exist"
			end
			return a, nil
		end

		function fs.readStamp(path)
			local path2, err = pathToDisk(base, path)
			if not path2 then
				return nil, err
			end
			local res = GetAssetSize(path2) or 0
			-- See wikiRead for rationale.
			if res <= 0 then
				return nil, nil, "does not exist"
			end
			-- stamp is empty as hint to wikiPageLinks that, frankly, we don't have a clue
			return res, ""
		end

		function fs.pathTable(prefix)
			local total = {}
			for _, namePre in ipairs(GetZipPaths(base)) do
				if GetAssetSize(namePre) > 0 then
					local name = namePre:sub(#base + 1)
					local parsed, err = pathParse(name)
					if parsed then
						local unparse = pathUnparse(parsed)
						if (not prefix) or (unparse:sub(1, #prefix) == prefix) then
							total[unparse] = true
						end
					end
				end
			end
			return total
		end

		function fs.write(path, data)
			local path2, err = pathToDisk(base, path)
			if not path2 then
				return nil, err
			end
			StoreAsset(path2, data)
			return true
		end

		function fs.delete(path)
			-- ugh this is so bad!
			return fs.write(path, "")
		end

		return fs
	end,
	newDiskFS = function (base)
		local fs = { readOnly = false }

		-- The Listing Cache exists because the wiki performs listing a _lot_ for various functions; we would like this to be fast, within reason.

		local listingCache = nil
		local function addFileToListingCache(virtualPath)
			local parsed, _ = wikiPathParse(virtualPath)
			if parsed then
				local unparse = wikiPathUnparse(parsed)
				listingCache[unparse] = true
			end
		end
		-- virtualBase might be "", "someDir/" ; never a filename
		local function addDirToListingCache(realBase, virtualBase)
			for name, kind, ino, off in assert(unix.opendir(realBase)) do
				if name == "." or name == ".." then
					-- just wonder what we've gotten ourselves into
				elseif kind == unix.DT_DIR then
					addDirToListingCache(realBase .. name .. "/", virtualBase .. name .. "/")
				elseif kind == unix.DT_REG then
					addFileToListingCache(virtualBase .. name)
				end
			end
		end
		local function getListingCache()
			if not listingCache then
				listingCache = {}
				addDirToListingCache(base, "")
			end
			return listingCache
		end

		-- Read --

		function fs.read(path)
			local path2, err = pathToDisk(base, path)
			if not path2 then
				return nil, err
			end
			local a, b = Slurp(path2)
			return a, b and tostring(b)
		end

		-- Returns size, stamp, error
		function fs.readStamp(path)
			local path2, err = pathToDisk(base, path)
			if not path2 then
				return nil, nil, err
			end
			local stat, err = unix.stat(path2)
			if not stat then
				return nil, nil, tostring(err)
			end
			local size = stat:size()
			return size, tostring(stat:mtim()) .. "|" .. tostring(stat:ino()) .. "|" .. tostring(size), nil
		end

		function fs.pathTable(prefix)
			if not prefix then
				return table.assign({}, getListingCache())
			end
			local total = {}
			for name, _ in pairs(getListingCache()) do
				if name:sub(1, #prefix) == prefix then
					total[name] = true
				end
			end
			return total
		end

		-- Write --

		-- Important note:
		-- This function needs to be as atomic as possible.
		-- Other processes should perceive a swap, ideally a different inode.
		function fs.write(path3, data)
			local path2, err = pathToDisk(base, path3)
			if not path2 then
				return nil, err
			end
			unix.makedirs(path.dirname(path2))
			local temp = base .. ".wikiWrite_" .. tostring(os.time()) .. "_" .. tostring(unix.getpid()) .. "_" .. EncodeHex(GetRandomBytes(16))
			local a, b = Barf(temp, data)
			if not b then
				-- success ; overwrite
				-- This is only 'guessable' without checking code, but:
				-- cosmopolitan libc guarantees move-replace semantics on Windows also.
				-- See https://github.com/jart/cosmopolitan/blob/master/libc/calls/renameat-nt.c#L92
				a, b = unix.rename(temp, path2)
			end
			-- no matter what, the temp file must be gone
			unix.unlink(temp)
			listingCache = nil
			return a, b and tostring(b)
		end

		function fs.delete(path3)
			local path2, err = pathToDisk(base, path3)
			if not path2 then
				return nil, err
			end
			local a, b = unix.unlink(path2)
			-- attempt to remove unused directories
			while #path2 > #base do
				unix.rmdir(path2)
				path2 = path.dirname(path2)
			end
			listingCache = nil
			return a, b and tostring(b)
		end

		return fs
	end
}
