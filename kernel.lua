-- TemplateWiki Kernel

local initialGlobals = {}
for k, v in pairs(_G) do
	initialGlobals[k] = v
end

ProgramMaxPayloadSize(0x1000000)

WIKI_BASE = "wiki/"

function table.deepcopy(t)
	if type(t) == "table" then
		local copy = {}
		for k, v in pairs(t) do
			copy[table.deepcopy(k)] = table.deepcopy(v)
		end
		return copy
	else
		return t
	end
end

-- The '~' character is used for filesystem storage, while the '/' character is canonical.
function wikiPathParse(path)
	if path:sub(1, 1) == "." then
		return nil, "hidden"
	end
	local res = {}
	for v in string.gmatch(path, "[^/_]+") do
		if v == "." or v == ".." then
			return nil, "traversal components"
		end
		if v:find("\\") then
			return nil, "traversal"
		end
		table.insert(res, v)
	end
	if #res == 0 then
		-- this is relied upon to resolve all empty paths
		return nil, "empty"
	end
	return res
end

function wikiPathUnparse(wp)
	local path = ""
	for k, v in ipairs(wp) do
		if k ~= 1 then
			path = path .. "/"
		end
		path = path .. v
	end
	return path
end

-- In order to avoid having to deal with directory nonsense, we play a game here.
-- Namely, '/' is used 'internally' while '_' is used 'externally'.
function wikiPathToDisk(path)
	local parsed, err = wikiPathParse(path)
	if not parsed then
		return nil, err
	end
	local path = WIKI_BASE
	for k, v in ipairs(parsed) do
		if k ~= 1 then
			path = path .. "_"
		end
		path = path .. v
	end
	return path
end

function safeSlurp(path)
	local path2, err = wikiPathToDisk(path)
	if not path2 then
		return nil, ("invalid path (" .. tostring(err) .. "): " .. path)
	end
	return Slurp(path2)
end

function safeBarf(path, data)
	local path2, err = wikiPathToDisk(path)
	if not path2 then
		return nil, ("invalid path (" .. tostring(err) .. "): " .. path)
	end
	return Barf(path2, data)
end

function wikiPathTable(prefix)
	local total = {}
	if prefix then
		for name, kind, ino, off in assert(unix.opendir(WIKI_BASE)) do
			local parsed, err = wikiPathParse(name)
			if parsed then
				local unparse = wikiPathUnparse(parsed)
				if unparse:sub(1, #prefix) == prefix then
					total[unparse] = true
				end
			end
		end
	else
		for name, kind, ino, off in assert(unix.opendir(WIKI_BASE)) do
			local parsed, err = wikiPathParse(name)
			if parsed then
				total[wikiPathUnparse(parsed)] = true
			end
		end
	end
	return total
end

function wikiPathList(prefix)
	local total = {}
	for k, _ in pairs(wikiPathTable(prefix)) do
		table.insert(total, k)
	end
	table.sort(total)
	return total
end

function wikiReadConfig(file, default)
	local value = safeSlurp(file) or ""
	value = value:match("[^\r\n]+") or default
	return value
end

function wikiResolvePage(wikiPath)
	local wikiPathParsed, err = wikiPathParse(wikiPath)
	if err == "empty" then
		wikiPathParsed = {"start"}
	end
	wikiPath = wikiPathUnparse(wikiPathParsed)
	-- does the file have an extension?
	local extIdx = wikiPathParsed[#wikiPathParsed]:find(".", 1, true)
	if not extIdx then
		-- no extension; find one or make one
		wikiPath = wikiPathList(wikiPath .. ".")[1] or (wikiPath .. "." .. wikiReadConfig("system/extensions/default.txt", "txt"))
		wikiPathParsed, err = wikiPathParse(wikiPath)
		assert(wikiPathParsed)
		extIdx = wikiPathParsed[#wikiPathParsed]:find(".", 1, true)
		assert(extIdx)
	end
	local ext = wikiPathParsed[#wikiPathParsed]:sub(extIdx + 1)
	return wikiPath, ext
end

function makeSandbox()
	local sandboxEnv

	local function safeLoad(contents, filename, mode, env)
		if rawequal(env, nil) then
			env = sandboxEnv
		end
		return load(contents, filename, "t", env)
	end

	local function safeLoadfile(path, mode, env)
		local code, err = safeSlurp(path)
		if not code then
			return nil, err
		end
		return safeLoad(code, path, mode, env)
	end

	local function safeDofile(path, ...)
		assert(path, "no path to dofile")
		local code, err = safeLoadfile(path)
		assert(code, err)
		return code(...)
	end

	local packageLoaded = {}
	local function safeRequire(path)
		if packageLoaded[path] then
			return packageLoaded[path]
		end
		packageLoaded[path] = safeDofile(path) or true
	end

	sandboxEnv = {
		-- Lua 5.4 global --
		assert = assert,
		collectgarbage = collectgarbage,
		dofile = safeDofile,
		error = error,
		-- _G is added
		getmetatable = getmetatable,
		ipairs = ipairs,
		load = safeLoad,
		loadfile = safeLoadfile,
		next = next,
		pairs = pairs,
		pcall = pcall,
		print = print,
		rawequal = rawequal,
		rawget = rawget,
		rawlen = rawlen,
		rawset = rawset,
		select = select,
		setmetatable = setmetatable,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		_VERSION = _VERSION,
		warn = warn,
		xpcall = xpcall,
		-- Lua 5.4 libraries --
		coroutine = table.deepcopy(coroutine),
		string = table.deepcopy(string),
		utf8 = table.deepcopy(utf8),
		table = table.deepcopy(table),
		math = table.deepcopy(math),
		package = { loaded = packageLoaded },
		require = safeRequire,
		debug = { traceback = debug.traceback },
		-- Redbean --
		Write = Write,
		SetStatus = SetStatus,
		SetHeader = SetHeader,
		SetCookie = SetCookie,
		GetParam = GetParam,
		EscapeHtml = EscapeHtml,
		EscapeIp = EscapeIp, -- undocumented?
		-- LaunchBrowser skipped...,
		CategorizeIp = CategorizeIp,
		DecodeLatin1 = DecodeLatin1,
		EncodeHex = EncodeHex,
		DecodeHex = DecodeHex,
		DecodeBase32 = DecodeBase32,
		EncodeBase32 = EncodeBase32,
		DecodeBase64 = DecodeBase64,
		EncodeBase64 = EncodeBase64,
		DecodeJson = DecodeJson,
		EncodeJson = EncodeJson,
		EncodeLua = EncodeLua,
		EncodeLatin1 = EncodeLatin1,
		EscapeFragment = EscapeFragment,
		EscapeHost = EscapeHost,
		EscapeLiteral = EscapeLiteral,
		EscapeParam = EscapeParam,
		EscapePass = EscapePass,
		EscapePath = EscapePath,
		EscapeSegment = EscapeSegment,
		EscapeUser = EscapeUser,
		-- EvadeDragnetSurveillance skipped...
		UuidV4 = UuidV4,
		UuidV7 = UuidV7,
		-- Fetch skipped...
		FormatHttpDateTime = FormatHttpDateTime,
		FormatIp = FormatIp,
		-- GetAsset* skipped...
		GetBody = GetBody,
		GetCookie = GetCookie,
		GetCryptoHash = GetCryptoHash,
		Curve25519 = Curve25519,
		GetRemoteAddr = GetRemoteAddr,
		GetResponseBody = GetResponseBody,
		GetClientAddr = GetClientAddr,
		GetClientFd = GetClientFd,
		IsClientUsingSsl = IsClientUsingSsl,
		GetServerAddr = GetServerAddr,
		GetDate = GetDate,
		GetHeader = GetHeader,
		GetHeaders = GetHeaders,
		GetLogLevel = GetLogLevel,
		GetHost = GetHost,
		GetHostOs = GetHostOs,
		GetHostIsa = GetHostIsa,
		GetMonospaceWidth = GetMonospaceWidth,
		GetMethod = GetMethod,
		GetParams = GetParams,
		GetPath = GetPath,
		GetEffectivePath = GetEffectivePath,
		GetScheme = GetScheme,
		GetSslIdentity = GetSslIdentity,
		GetStatus = GetStatus,
		GetTime = GetTime,
		GetUrl = GetUrl,
		GetHttpVersion = GetHttpVersion,
		GetHttpReason = GetHttpReason,
		GetRandomBytes = GetRandomBytes,
		GetRedbeanVersion = GetRedbeanVersion,
		GetZipPaths = GetZipPaths,
		HasParam = HasParam,
		-- HidePath / IsHiddenPath skipped
		IsPublicIp = IsPublicIp,
		IsPrivateIp = IsPrivateIp,
		IsLoopbackIp = IsLoopbackIp,
		-- IsAssetCompressed skipped
		IndentLines = IndentLines,
		-- LoadAsset / StoreAsset skipped
		Log = Log,
		ParseHttpDateTime = ParseHttpDateTime,
		ParseUrl = ParseUrl,
		IsAcceptablePath = IsAcceptablePath,
		IsReasonablePath = IsReasonablePath,
		EncodeUrl = EncodeUrl,
		ParseIp = ParseIp,
		-- Program*, IsDaemon, Program* skipped
		Slurp = safeSlurp,
		Barf = safeBarf,
		Sleep = Sleep,
		-- Route, RouteHost, RoutePath skipped
		ServeAsset = ServeAsset,
		ServeError = ServeError,
		ServeRedirect = ServeRedirect,
		-- SetLogLevel skipped
		VisualizeControlCodes = VisualizeControlCodes,
		Underlong = Underlong,
		Crc32 = Crc32,
		Crc32c = Crc32c,
		Md5 = Md5,
		Sha1 = Sha1,
		Sha224 = Sha224,
		Sha256 = Sha256,
		Sha384 = Sha384,
		Sha512 = Sha512,
		Bsf = Bsf,
		Bsr = Bsr,
		Popcnt = Popcnt,
		Rdtsc = Rdtsc,
		Lemur64 = Lemur64,
		Rand64 = Rand64,
		Rdrand = Rdrand,
		Rdseed = Rdseed,
		GetCpuCount = GetCpuCount,
		GetCpuCore = GetCpuCore,
		GetCpuNode = GetCpuNode,
		Decimate = Decimate,
		MeasureEntropy = MeasureEntropy,
		Deflate = Deflate,
		Inflate = Inflate,
		Benchmark = Benchmark,
		oct = oct,
		hex = hex,
		bin = bin,
		-- ResolveIp skipped...
		IsTrustedIp = IsTrustedIp,
		-- Program*, AcquireToken, CountTokens, Blackhole skipped...
		-- Redbean modules --
		argon2 = table.deepcopy(argon2),
		re = table.deepcopy(re),
		-- Redbean constants --
		kLogDebug = kLogDebug,
		kLogError = kLogError,
		kLogFatal = kLogFatal,
		kLogInfo = kLogInfo,
		kLogVerbose = kLogVerbose,
		kLogWarn = kLogWarn,
		kUrlLatin1 = kUrlLatin1,
		kUrlPlus = kUrlPlus,
		-- TemplateWiki --
		wikiPathParse = wikiPathParse,
		wikiPathUnparse = wikiPathUnparse,
		wikiPathTable = wikiPathTable,
		wikiPathList = wikiPathList,
		wikiReadConfig = wikiReadConfig,
		wikiResolvePage = wikiResolvePage
	}
	sandboxEnv._G = sandboxEnv
	return sandboxEnv
end

function checkSandbox()
	local sandbox = makeSandbox()
	local exclusionReasons = {
		AcquireToken = true,
		Blackhole = true,
		Compress = true,
		CountTokens = true,
		EvadeDragnetSurveillance = true,
		Fetch = true,
		GetAssetComment = true,
		GetAssetLastModifiedTime = true,
		GetAssetMode = true,
		GetAssetSize = true,
		GetComment = true,
		GetFragment = true,
		GetLastModifiedTime = true,
		GetPass = true,
		GetPayload = true,
		GetPort = true,
		GetUser = true,
		GetVersion = true,
		HasControlCodes = true,
		HidePath = true,
		HighwayHash64 = true,
		IsAcceptableHost = true,
		IsAcceptablePort = true,
		IsAssetCompressed = true,
		IsCompressed = true,
		IsDaemon = true,
		IsHeaderRepeatable = true,
		IsHiddenPath = true,
		IsValidHttpToken = true,
		LaunchBrowser = true,
		LoadAsset = true,
		ParseHost = true,
		ParseParams = true,
		ProgramAddr = true,
		ProgramBrand = true,
		ProgramCache = true,
		ProgramCertificate = true,
		ProgramContentType = true,
		ProgramDirectory = true,
		ProgramGid = true,
		ProgramHeader = true,
		ProgramHeartbeatInterval = true,
		ProgramLogBodies = true,
		ProgramLogMessages = true,
		ProgramLogPath = true,
		ProgramMaxPayloadSize = true,
		ProgramMaxWorkers = true,
		ProgramPidPath = true,
		ProgramPort = true,
		ProgramPrivateKey = true,
		ProgramRedirect = true,
		ProgramSslCiphersuite = true,
		ProgramSslClientVerify = true,
		ProgramSslFetchVerify = true,
		ProgramSslInit = true,
		ProgramSslPresharedKey = true,
		ProgramSslRequired = true,
		ProgramSslTicketLifetime = true,
		ProgramTimeout = true,
		ProgramTokenBucket = true,
		ProgramTrustedIp = true,
		ProgramUid = true,
		ProgramUniprocess = true,
		ResolveIp = true,
		Route = true,
		RouteHost = true,
		RoutePath = true,
		ServeIndex = true,
		ServeListing = true,
		ServeStatusz = true,
		SetLogLevel = true,
		StoreAsset = true,
		Uncompress = true,
		__signal_handlers = true,
		dofile = true,
		finger = true,
		io = true,
		lsqlite3 = true,
		maxmind = true,
		os = true,
		path = true,
		re = true,
		unix = true,
	}
	local res = {}
	for k, v in pairs(initialGlobals) do
		if not sandbox[k] then
			if not exclusionReasons[k] then
				table.insert(res, k)
			end
		end
	end
	table.sort(res)
	for _, v in ipairs(res) do
		print(v .. " = true,")
	end
end

checkSandbox()

function OnWorkerStart()
end

function OnHttpRequest()
	local wikiPath, ext = wikiResolvePage(GetPath())
	local action = GetParam("action") or "default"

	local sandbox = makeSandbox()
	sandbox.wikiRequestPath = wikiPath
	sandbox.wikiRequestExtension = ext
	sandbox.wikiRequestAction = action

	-- Kernel routes to system/action/{action}.lua
	local where = "system/action/" .. action .. ".lua"
	local code, err = safeSlurp(where)
	if not code then
		if action ~= "default" then
			ServeRedirect(303, GetPath())
			return
		else
			Write(safeSlurp(wikiPath))
			return
		end
	end
	load(code, where, "t", sandbox)()
end
