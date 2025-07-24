-- 'Lua-Sandboxed Redbean'
-- This does two things:
-- 1. Hardens and extends the Lua 5.4 environment
-- 2. Provides the actual sandbox
-- 3. Provides functions missing in older versions of Redbean

local function hardenMetatables()
	-- First, work around a 'questionable decision' (I'm half-tempted to call it a security hazard) with this series of lauxlib functions:
	-- luaL_newmetatable, luaL_checkudata, luaL_testudata all do very dodgy things with exposing metatables where they shouldn't necessarily be exposed.
	-- The string metatable, also, is exposed.
	local these = {}
	for k, v in pairs(debug.getregistry()) do
		if type(v) == "table" then
			if v.__name then
				-- this was probably created with luaL_newmetatable and is intended to secure C objects
				v.__metatable = v.__name
				table.insert(these, k)
			end
		end
	end
	Log(kLogInfo, "beanbox: patched metatables: " .. EncodeLua(these))
	getmetatable("").__metatable = "string"
end

hardenMetatables()

-- Redbean 2.2 does not have these functions...
if not EncodeHex then
	function EncodeHex(data)
		data = data:gsub(".", function (v) return string.format("%02X", v:byte()) end)
		return data
	end
end
if not DecodeHex then
	function DecodeHex(data)
		local total = ""
		local at = 1
		while at < #data + 1 do
			local chk = data:sub(at, at + 1)
			assert(#chk == 2, "bad hex")
			local res = assert(tonumber("0x" .. chk), "bad hex")
			total = total .. string.char(res)
			at = at + 2
		end
		return total
	end
end
if not GetHostIsa then
	function GetHostIsa()
		return "X86_64"
	end
end

-- the following globals are known to just 'go missing' in various configurations
local knownToGoMissing = {
	Curve25519 = true,
	DecodeBase32 = true,
	EncodeBase32 = true,
	HighwayHash64 = true,
	UuidV4 = true,
	UuidV7 = true
}

-- now snapshot globals --

local initialGlobals = {}
for k, v in pairs(_G) do
	initialGlobals[k] = v
end

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
local treatments = {
	-- Lua 5.4 global --
	assert = "include",
	collectgarbage = "include",
	dofile = "special",
	error = "include",
	_G = function (env) return env end,
	getmetatable = "include",
	ipairs = "include",
	load = "special",
	loadfile = "special",
	next = "include",
	pairs = "include",
	pcall = "include",
	print = "-",
	rawequal = "include",
	rawget = "include",
	rawlen = "include",
	rawset = "include",
	select = "include",
	setmetatable = "include",
	tonumber = "include",
	tostring = "include",
	type = "include",
	_VERSION = "include",
	warn = "include",
	xpcall = "include",
	-- Lua 5.4 libraries --
	io = "-",
	package = "-",
	path = "-",
	require = "-",
	coroutine = "deepcopy",
	string = "deepcopy",
	utf8 = "deepcopy",
	table = "deepcopy",
	math = "deepcopy",
	debug = function (env) return { traceback = debug.traceback } end,
	os = function (env) return { clock = os.clock, date = os.date, difftime = os.difftime, time = os.time } end,
	-- Redbean --
	-- These functions, ideally, should be in roughly their order as in the Redbean documentation.
	-- That hasn't been held to, but the other stuff should mean it's mostly okay.
	Write = "include",
	SetStatus = "include",
	SetHeader = "include",
	SetCookie = "include",
	GetParam = "include",
	EscapeHtml = "include",
	LaunchBrowser = "-",
	CategorizeIp = "include",
	DecodeLatin1 = "include",
	EncodeHex = "include",
	DecodeHex = "include",
	DecodeBase32 = "include",
	EncodeBase32 = "include",
	DecodeBase64 = "include",
	EncodeBase64 = "include",
	DecodeJson = "include",
	EncodeJson = "include",
	EncodeLua = "include",
	EncodeLatin1 = "include",
	EscapeFragment = "include",
	EscapeHost = "include",
	EscapeLiteral = "include",
	EscapeParam = "include",
	EscapePass = "include",
	EscapePath = "include",
	EscapeSegment = "include",
	EscapeUser = "include",
	EvadeDragnetSurveillance = "-",
	UuidV4 = "include",
	UuidV7 = "include",
	Fetch = "-",
	FormatHttpDateTime = "include",
	FormatIp = "include",
	GetAssetComment = "include",
	GetComment = "-",
	GetAssetLastModifiedTime = "include",
	GetLastModifiedTime = "-",
	GetAssetMode = "include",
	GetAssetSize = "include",
	GetBody = "include",
	GetCookie = "include",
	GetCryptoHash = "include",
	Curve25519 = "include",
	GetRemoteAddr = "include",
	GetResponseBody = "include",
	GetClientAddr = "include",
	GetClientFd = "include",
	IsClientUsingSsl = "include",
	GetServerAddr = "include",
	GetDate = "include",
	GetHeader = "include",
	GetHeaders = "include",
	GetLogLevel = "include",
	GetHost = "include",
	GetHostOs = "include",
	GetHostIsa = "include",
	GetMonospaceWidth = "include",
	GetMethod = "include",
	GetParams = "include",
	GetPath = "include",
	GetEffectivePath = "include",
	GetScheme = "include",
	GetSslIdentity = "include",
	GetStatus = "include",
	GetTime = "include",
	GetUrl = "include",
	GetHttpVersion = "include",
	GetHttpReason = "include",
	GetRandomBytes = "include",
	GetRedbeanVersion = "include",
	GetZipPaths = "include",
	HasParam = "include",
	HidePath = "-",
	IsHiddenPath = "-",
	IsPublicIp = "include",
	IsPrivateIp = "include",
	IsLoopbackIp = "include",
	IsAssetCompressed = "include",
	IsCompressed = "-",
	IndentLines = "include",
	LoadAsset = "include",
	StoreAsset = "-",
	Log = "include",
	ParseHttpDateTime = "include",
	ParseUrl = "include",
	IsAcceptablePath = "include",
	IsReasonablePath = "include",
	EncodeUrl = "include",
	ParseIp = "include",
	ProgramAddr = "-",
	ProgramBrand = "-",
	ProgramCache = "-",
	ProgramCertificate = "-",
	ProgramContentType = "-",
	ProgramHeader = "-",
	ProgramHeartbeatInterval = "-",
	ProgramTimeout = "-",
	ProgramPort = "-",
	ProgramMaxPayloadSize = "-",
	ProgramMaxWorkers = "-",
	ProgramPrivateKey = "-",
	ProgramRedirect = "-",
	ProgramSslTicketLifetime = "-",
	ProgramSslPresharedKey = "-",
	ProgramSslFetchVerify = "-",
	ProgramSslClientVerify = "-",
	ProgramSslRequired = "-",
	ProgramSslCiphersuite = "-",
	IsDaemon = "-",
	ProgramUid = "-",
	ProgramGid = "-",
	ProgramDirectory = "-",
	ProgramLogMessages = "-",
	ProgramLogBodies = "-",
	ProgramLogPath = "-",
	ProgramPidPath = "-",
	ProgramUniprocess = "-",
	Slurp = "-",
	Barf = "-",
	Sleep = "include",
	Route = "include",
	RouteHost = "include",
	RoutePath = "include",
	ServeAsset = "include",
	ServeError = "include",
	ServeRedirect = "include",
	SetLogLevel = "-",
	VisualizeControlCodes = "include",
	Underlong = "include",
	Crc32 = "include",
	Crc32c = "include",
	Md5 = "include",
	Sha1 = "include",
	Sha224 = "include",
	Sha256 = "include",
	Sha384 = "include",
	Sha512 = "include",
	Bsf = "include",
	Bsr = "include",
	Popcnt = "include",
	Rdtsc = "include",
	Lemur64 = "include",
	Rand64 = "include",
	Rdrand = "include",
	Rdseed = "include",
	GetCpuCount = "include",
	GetCpuCore = "include",
	GetCpuNode = "include",
	Decimate = "include",
	MeasureEntropy = "include",
	Deflate = "include",
	Inflate = "include",
	Benchmark = "include",
	oct = "include",
	hex = "include",
	bin = "include",
	ResolveIp = "-",
	IsTrustedIp = "include",
	ProgramTrustedIp = "-",
	ProgramTokenBucket = "-",
	AcquireToken = "-",
	CountTokens = "-",
	Blackhole = "-",
	-- Redbean - Undocumented (?)
	ProgramSslInit = "-",
	EscapeIp = "include",
	Compress = "-",
	GetFragment = "-",
	GetPass = "-",
	GetPayload = "-",
	GetPort = "-",
	GetUser = "-",
	GetVersion = "-",
	HasControlCodes = "-",
	HighwayHash64 = "-",
	IsAcceptableHost = "-",
	IsAcceptablePort = "-",
	IsHeaderRepeatable = "-",
	IsValidHttpToken = "-",
	ParseHost = "-",
	ParseParams = "-",
	ServeIndex = "-",
	ServeListing = "-",
	ServeStatusz = "-",
	Uncompress = "-",
	-- Redbean modules --
	argon2 = "deepcopy",
	re = "deepcopy",
	finger = "-",
	lsqlite3 = "-",
	maxmind = "-",
	unix = "-",
	-- Redbean constants --
	kLogDebug = "include",
	kLogError = "include",
	kLogFatal = "include",
	kLogInfo = "include",
	kLogVerbose = "include",
	kLogWarn = "include",
	kUrlLatin1 = "include",
	kUrlPlus = "include",
	-- Redbean misc
	__signal_handlers = "-",
	arg = "-",
	argv = "-"
}

local function makeSandbox(safeReadfile)
	safeReadfile = safeReadfile or function ()
		return nil, "not supported"
	end

	local sandboxEnv

	local function safeLoad(contents, filename, mode, env)
		if rawequal(env, nil) then
			env = sandboxEnv
		end
		return load(contents, filename, "t", env)
	end

	local function safeLoadfile(path, mode, env)
		local code, err = safeReadfile(path)
		if not code then
			return nil, err
		end
		return safeLoad(code, path, mode, env)
	end

	local function safeDofile(path, ...)
		assert(path, "no path to dofile")
		local code, err = safeLoadfile(path)
		assert(code, path .. ": " .. tostring(err))
		return code(...)
	end

	sandboxEnv = {
		load = safeLoad,
		loadfile = safeLoadfile,
		dofile = safeDofile
	}

	for k, v in pairs(treatments) do
		if v == "include" then
			sandboxEnv[k] = _G[k]
		elseif v == "-" then
			-- do nothing
		elseif v == "special" then
			assert(sandboxEnv[k])
		elseif v == "deepcopy" then
			sandboxEnv[k] = table.deepcopy(_G[k])
		elseif type(v) == "function" then
			sandboxEnv[k] = v(sandboxEnv)
		else
			error("Bad treatment of " .. k)
		end
	end

	return sandboxEnv
end

local function checkTreatments()
	local res = {}
	for k, v in pairs(initialGlobals) do
		if not treatments[k] then
			table.insert(res, "unclassified global: " .. k)
		end
	end
	for k, v in pairs(treatments) do
		if (not initialGlobals[k]) and not knownToGoMissing[k] then
			table.insert(res, "missing global: " .. k)
		end
	end
	table.sort(res)
	for _, v in ipairs(res) do
		-- If you're seeing this, it means your Redbean's functions and beanbox's function list don't agree.
		-- This is probably harmless; beanbox won't include new globals.
		Log(kLogWarn, v)
	end
end

checkTreatments()

return makeSandbox
