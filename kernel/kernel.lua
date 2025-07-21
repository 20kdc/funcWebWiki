-- wiki kernel --

local initialGlobals = {}
for k, v in pairs(_G) do
	initialGlobals[k] = v
end

-- autodetect / parse args --

WIKI_BASE = "wiki/"
wikiAbsoluteBase = "/"
wikiReadOnly = false
local assetWikiLooksPresent = not not LoadAsset("/wiki/system_lib_kernel.lua")
local fileWikiLooksPresent = not not Slurp(WIKI_BASE .. "system_lib_kernel.lua")
local preferAssetWiki = false

local KEDIT_PASSWORD = os.getenv("WIKI_TWM_PASSWORD")
if KEDIT_PASSWORD == "" then
	KEDIT_PASSWORD = nil
end

local help = [[

funcWebWiki kernel

can serve from either a directory (default `wiki/`) or Redbean zip assets
 will prefer the directory if it seems valid (`system_lib_kernel.lua` found)
 overridable with `--prefer-asset-wiki`
 if neither is valid, file wiki will be attempted (a fun bootstrap challenge)

Redbean options accepted as normal; '--' divides between Redbean options and
 funcWebWiki options, which are:

	--help : this text
	--url-base /mywiki/ : sets the URL base to `/mywiki/`
		the URL base is useful for reverse-proxy-subdirectory layouts
	--wiki-base wiki/ : sets the wiki base to the default, `wiki/`
		the wiki base is the directory wiki files are stored in
	--read-only : the wiki cannot write or delete files
	--prefer-asset-wiki : even if a file wiki is present,
		prefer the read-only 'asset wiki', if found

environment variable WIKI_TWM_PASSWORD sets 'tactical witch mode' password
 for live editing of even broken wikis / remote bootstrapping
]]
if assetWikiLooksPresent then
	help = help .. "\na valid asset wiki appears present; extract with unzip for editing!\n"
end

local function parseArgs()
	local argi = 1
	local function getNextArg()
		local arg = argv[argi]
		argi = argi + 1
		return arg
	end
	while true do
		local arg = getNextArg()
		if arg == nil then
			break
		end
		if arg == "--help" then
			print(help)
			os.exit(0)
		elseif arg == "--url-base" then
			wikiAbsoluteBase = assert(getNextArg(), "no parameter given to --url-base")
		elseif arg == "--wiki-base" then
			WIKI_BASE = assert(getNextArg(), "no parameter given to --wiki-base")
		elseif arg == "--read-only" then
			wikiReadOnly = true
		elseif arg == "--prefer-asset-wiki" then
			preferAssetWiki = true
		else
			error("Unrecognized arg " .. arg .. "\n" .. help)
		end
	end
end
parseArgs()

if not preferAssetWiki then
	if assetWikiLooksPresent and fileWikiLooksPresent then
		assetWikiLooksPresent = false
	end
end

-- utilties --

function table.assign(t, ...)
	for _, v in ipairs({...}) do
		if v then
			for k, kv in pairs(v) do
				t[k] = kv
			end
		end
	end
	return t
end

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

if assetWikiLooksPresent then
	WIKI_BASE = "/wiki/"
	Log(kLogInfo, "wiki in read-only Redbean asset mode (unzip to edit)")
	wikiReadOnly = true

	function safeSlurp(path)
		local path2, err = wikiPathToDisk(path)
		if not path2 then
			return nil, ("invalid path (" .. tostring(err) .. "): " .. path)
		end
		local a = LoadAsset(path2)
		if not a then
			return nil, "does not exist"
		end
		return a, nil
	end

	function wikiPathTable(prefix)
		local total = {}
		for _, namePre in ipairs(GetZipPaths(WIKI_BASE)) do
			local name = namePre:sub(#WIKI_BASE + 1)
			local parsed, err = wikiPathParse(name)
			if parsed then
				local unparse = wikiPathUnparse(parsed)
				if (not prefix) or (unparse:sub(1, #prefix) == prefix) then
					total[unparse] = true
				end
			end
		end
		return total
	end
else
	Log(kLogInfo, "wiki in directory mode")

	function safeSlurp(path)
		local path2, err = wikiPathToDisk(path)
		if not path2 then
			return nil, ("invalid path (" .. tostring(err) .. "): " .. path)
		end
		local a, b = Slurp(path2)
		return a, b and tostring(b)
	end

	function safeBarf(path, data)
		local path2, err = wikiPathToDisk(path)
		if not path2 then
			return nil, ("invalid path (" .. tostring(err) .. "): " .. path)
		end
		local a, b = Barf(path2, data)
		return a, b and tostring(b)
	end

	function wikiDelete(path)
		local path2, err = wikiPathToDisk(path)
		if not path2 then
			return nil, ("invalid path (" .. tostring(err) .. "): " .. path)
		end
		local a, b = unix.unlink(path2)
		return a, b and tostring(b)
	end

	function wikiPathTable(prefix)
		local total = {}
		for name, kind, ino, off in assert(unix.opendir(WIKI_BASE)) do
			local parsed, err = wikiPathParse(name)
			if parsed then
				local unparse = wikiPathUnparse(parsed)
				if (not prefix) or (unparse:sub(1, #prefix) == prefix) then
					total[unparse] = true
				end
			end
		end
		return total
	end
end

if wikiReadOnly then
	function safeBarf(path, data)
		return nil, "wiki read-only"
	end
	function wikiDelete(path)
		return nil, "wiki read-only"
	end
end

function wikiPathList(prefix)
	local total = {}
	for k, _ in pairs(wikiPathTable(prefix)) do
		table.insert(total, k)
	end
	table.sort(total)
	return total
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
		assert(code, "package '" .. path .. "': " .. tostring(err))
		return code(...)
	end

	local packageLoaded = {}
	local function safeRequire(path)
		if packageLoaded[path] then
			return packageLoaded[path]
		end
		local res = safeDofile(path) or true
		packageLoaded[path] = res
		return res
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
		os = { clock = os.clock, date = os.date, difftime = os.difftime, time = os.time },
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
		-- wiki --
		wikiPathParse = wikiPathParse,
		wikiPathUnparse = wikiPathUnparse,
		wikiPathTable = wikiPathTable,
		wikiPathList = wikiPathList,
		wikiDelete = wikiDelete,
		wikiAbsoluteBase = wikiAbsoluteBase,
		wikiReadOnly = wikiReadOnly
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
		arg = true,
		argv = true,
		dofile = true,
		finger = true,
		io = true,
		lsqlite3 = true,
		maxmind = true,
		path = true,
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
		-- If you're seeing this, it means your Redbean has functions which haven't been explicitly denied but were implicitly denied.
		print(v .. " = true,")
	end
end

checkSandbox()

function makeEnv()
	local sandbox = makeSandbox()
	setmetatable(sandbox, {
		__index = function (table, key)
			-- print("__index on sandbox, " .. tostring(key))
			local value = table.require("system/lib/" .. key .. ".lua")
			assert(value ~= nil, "nil global '" .. key .. "' is erroneous")
			rawset(table, key, value)
			return value
		end,
		__newindex = function (table, key, value)
			error("Globals that are not part of kernel should only be declared using system/lib pages. key: " .. tostring(key))
		end,
		__metatable = "globals protector"
	})
	return sandbox
end

function OnWorkerStart()
end

function OnHttpRequest()
	local path = GetPath()
	if path:sub(1, 9) == "/_assets/" then
		return ServeAsset(path:sub(9))
	end
	local ewm = GetParam("_twm")
	if KEDIT_PASSWORD and (ewm == KEDIT_PASSWORD) then
		if GetMethod() == "POST" then
			local code = GetParam("code")
			if code then
				code = code:gsub("\r", "")
				safeBarf(path, code)
			end
		end
		Write("<h2>funcWebWiki: tactical witch mode, editing: " .. EscapeHtml(path) .. "</h2>\n")
		Write("<form method=\"post\">\n")
		Write("<textarea id=\"editor\" name=\"code\" cols=80 rows=25>")
		Write(EscapeHtml(safeSlurp(path)))
		Write("</textarea><br/>\n")
		Write("<style>textarea { tab-size: 4; }</style>\n")
		Write([[<script>
		var editor = document.getElementById("editor");
		if (editor) {
			editor.onkeydown = function (ev) {
				if (ev.key == "Tab") {
					editor.setRangeText("\t", editor.selectionStart, editor.selectionEnd, "end");
					// console.log("debug", ev);
					ev.preventDefault();
				}
			}
		}
		</script>]])
		Write("\n<input type=\"submit\">\n")
		Write("</form>\n")
		Write("<h2>all files...</h2>\n")
		Write("<ul>\n")
		for _, v in ipairs(wikiPathList()) do
			Write("<li><a href=\"" .. EscapeHtml(v .. "?_twm=" .. ewm) .. "\">" .. EscapeHtml(v) .. "</a></li>\n")
		end
		Write("</ul>")
		return
	end
	makeEnv().dofile("system/lib/kernel.lua")
end
