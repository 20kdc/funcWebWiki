-- wiki kernel --

-- rewrite package paths; hidden directories are not very fun
local oldPackagePath = package.path
package.path = package.path:gsub("/%.lua/", "/")
Log(kLogInfo, "package path rewrite: " .. oldPackagePath .. " -> " .. package.path)

-- setmetatable(_G, {__newindex = function (t, k, v) rawset(t, k, v) print("GLOBAL: " .. k) end})

-- setup utilities and safety measures
local beanbox = require("beanbox")

-- filesystem module
local wikifs = require("wikifs")

-- helptext --

local help = [[

funcWebWiki kernel

can serve from either a directory (default `wiki/`) or Redbean zip assets
 will prefer the directory if it seems valid (`system/request.lua` found)
 overridable with `--prefer-asset-wiki`
 if neither is valid, file wiki will be attempted (a fun bootstrap challenge)

Redbean options accepted as normal; '--' divides between Redbean options and
 funcWebWiki options, which are:

  --help : prints this text to stdout. also exits *immediately*
  --url-base /mywiki/ : sets the URL base to `/mywiki/`
    the URL base is useful for reverse-proxy-subdirectory layouts
  --strip-prefix /mywiki/ : requires all requests have prefix `/mywiki/`, and
    then strips/replaces it with `/` ; always use with `--url-base`
  --wiki-base wiki/ : sets the wiki base to the default, `wiki/`
    the wiki base is the directory wiki files are stored in
    setting this forces file wiki unless other options intervene
  --read-only : the wiki cannot write or delete files
  --asset-wiki : unless --pack/--unpack intervene, forces asset wiki.
  --public-unsafe : by default, -l 127.0.0.1 is applied.
    beware that funcWebWiki is not safe for public access by default.
  --unsandboxed-unsafe : gives access to all APIs. ***BE CAREFUL!***
  --no-favicon : disables hard-coded routes for `/favicon.ico` & `robots.txt`.
  --payload-size BYTES : the funcWebWiki sets payload size to 16MB by default
    in read-only mode, Redbean's default is used. this overrides both

'operators' (if any specified, exits after all complete. '--continue' cancels)
  --trigger TRIGGER : runs system/triggers/TRIGGER.lua
    TRIGGER is a 'URL'; SetStatus/SetHeader dummies, GetParam & Write work
  --unpack : extract from asset-wiki, force file-wiki, triggers follow
    beware: does not clean the directory!
  --pack : force file-wiki, triggers happen, pack to asset-wiki,
    force asset-wiki, beware: does not clean the ZIP!

environment variable WIKI_TWM_PASSWORD sets 'tactical witch mode' password
 for live editing of even broken wikis / remote bootstrapping
environment variable WIKI_BASIC_AUTH can be set to a 'username:password'
]]

-- very ad-hoc early test
if (GetAssetSize("/wiki/system/request.lua") or 0) > 0 then
	help = help .. "\na valid asset wiki appears present; extract with --unpack for editing!\n"
end

-- autodetect / parse args --

local wikiBase = "wiki/"
wikiAbsoluteBase = "/"
local stripPrefix = nil
local doReadOnly = false
local doForceAssetWiki = false
local doWasWikiBaseSet = false
local publicUnsafe = false
local unsandboxedUnsafe = false
local doUnpack = false
local doPack = false
local scheduledTriggers = {}
-- doContinue overrules doExit
local doContinue = false
local doExit = false
local favicon = true
local payloadSizeOverride = nil

local KEDIT_PASSWORD = os.getenv("WIKI_TWM_PASSWORD")
if KEDIT_PASSWORD == "" then
	KEDIT_PASSWORD = nil
end

local BASIC_AUTH = os.getenv("WIKI_BASIC_AUTH")
if BASIC_AUTH == "" then
	BASIC_AUTH = nil
end
if BASIC_AUTH then
	BASIC_AUTH = "Basic " .. EncodeBase64(BASIC_AUTH)
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
		elseif arg == "--strip-prefix" then
			stripPrefix = assert(getNextArg(), "no parameter given to --strip-prefix")
		elseif arg == "--wiki-base" then
			wikiBase = assert(getNextArg(), "no parameter given to --wiki-base")
			if wikiBase:sub(#wikiBase) ~= "/" then
				wikiBase = wikiBase .. "/"
			end
			doWasWikiBaseSet = true
		elseif arg == "--read-only" then
			doReadOnly = true
		elseif arg == "--asset-wiki" then
			doForceAssetWiki = true
		elseif arg == "--public-unsafe" then
			publicUnsafe = true
		elseif arg == "--unsandboxed-unsafe" then
			unsandboxedUnsafe = true
		elseif arg == "--unpack" then
			-- force disk backend
			doUnpack = true
			doExit = true
		elseif arg == "--pack" then
			doPack = true
			doExit = true
		elseif arg == "--continue" then
			doContinue = true
		elseif arg == "--trigger" then
			local val = assert(getNextArg(), "no parameter given to --trigger")
			table.insert(scheduledTriggers, val)
			doExit = true
		elseif arg == "--no-favicon" then
			favicon = false
		elseif arg == "--payload-size" then
			payloadSizeOverride = assert(tonumber(getNextArg()), "bad parameter given to --payload-size")
		else
			error("Unrecognized arg " .. arg .. "\n" .. help)
		end
	end
end

parseArgs()

-- setup FS and detect self-modification capability

local diskFs = wikifs.newDiskFS(wikiBase)

local assetFs = wikifs.newAssetFS("/wiki/")

if not pcall(function ()
	-- Redbean doesn't appear to report if it's allowed to self-modify.
	-- But we can make a very sketchy guess based on Redbean 2.2's behaviour.
	if not unix.fcntl(3, unix.F_SETLKW, unix.F_WRLCK) then
		-- failed
		wikifs.makeFSReadOnly(assetFs)
	else
		-- ok, unlock
		unix.fcntl(3, unix.F_SETLKW, unix.F_UNLCK)
	end
end) then
	-- if things go really wrong, make *sure* we mark the FS read-only
	wikifs.makeFSReadOnly(assetFs)
end

-- do pack/unpack from assets if asked.
-- sequence of events

local function fsTransfer(from, to, verbed)
	local count = 0
	for name, _ in pairs(from.pathTable("")) do
		local oldLogLevel = GetLogLevel()
		SetLogLevel(kLogWarn)
		to.write(name, from.read(name))
		SetLogLevel(oldLogLevel)
		count = count + 1
	end
	print(tostring(count) .. " files " .. verbed)
end

local primaryFs

if doUnpack then
	unix.makedirs(wikiBase)
	fsTransfer(assetFs, diskFs, "unpacked")
end

if doUnpack or doPack then
	primaryFs = diskFs
end

-- if pack/unpack didn't force it, pick which FS to use going forward

if not primaryFs then
	if doForceAssetWiki then
		primaryFs = assetFs
	elseif doWasWikiBaseSet then
		primaryFs = diskFs
	else
		-- now it's time to guess
		local fileWikiLooksPresent = not not diskFs.readStamp("system/request.lua")
		local assetWikiLooksPresent = not not assetFs.readStamp("system/request.lua")
		if fileWikiLooksPresent then
			primaryFs = diskFs
		elseif assetWikiLooksPresent then
			primaryFs = assetFs
		else
			primaryFs = diskFs
		end
	end
end

-- pull globals from wikifs

wikiPathParse = wikifs.pathParse
wikiPathUnparse = wikifs.pathUnparse

local function rebuildFSGlobals()
	wikiReadOnly = doReadOnly or primaryFs.readOnly
	wikiRead = primaryFs.read
	wikiReadStamp = primaryFs.readStamp
	wikiPathTable = primaryFs.pathTable
	wikiWrite = primaryFs.write
	wikiDelete = primaryFs.delete
end
rebuildFSGlobals()

-- final touches on the environment

function wikiPathList(prefix)
	local total = {}
	for k, _ in pairs(wikiPathTable(prefix)) do
		table.insert(total, k)
	end
	table.sort(total)
	return total
end

function wikiMakeEnv()
	local sandbox
	if unsandboxedUnsafe then
		-- _I wonder what we've gotten ourselves into..._
		sandbox = table.assign({}, _G)
		sandbox._G = sandbox
		-- we have to swap this out or else code will env-escape by *accident*
		sandbox.load = beanbox.makeLoad(sandbox)
	else
		sandbox = beanbox.makeSandbox()
		-- globals from wikifs
		sandbox.wikiPathParse = wikiPathParse
		sandbox.wikiPathUnparse = wikiPathUnparse
		sandbox.wikiPathTable = wikiPathTable
		sandbox.wikiRead = wikiRead
		sandbox.wikiReadStamp = wikiReadStamp
		sandbox.wikiWrite = wikiWrite
		sandbox.wikiDelete = wikiDelete
		-- from here
		sandbox.wikiPathList = wikiPathList
		sandbox.wikiAbsoluteBase = wikiAbsoluteBase
		sandbox.wikiReadOnly = wikiReadOnly
	end

	local safeLoad = sandbox.load

	local function safeLoadfile(path, mode, env)
		local code, err = wikiRead(path)
		if not code then
			return nil, err
		end
		return safeLoad(code, path, mode, env)
	end

	sandbox.loadfile = safeLoadfile

	function sandbox.dofile(path, ...)
		assert(path, "no path to dofile")
		local code, err = safeLoadfile(path)
		assert(code, path .. ": " .. tostring(err))
		return code(...)
	end

	setmetatable(sandbox, {
		__index = function (table, key)
			-- print("__index on sandbox, " .. tostring(key))
			local value = table.dofile("system/lib/" .. key .. ".lua")
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

function wikiMakeEnvEmuRequest(options)
	local method = options.method or "GET"
	local params = options.params or {}
	local parsedUrl = options.parsedUrl or ParseUrl(options.url, kUrlPlus)
	for _, v in ipairs(parsedUrl.params) do
		params[v[1]] = v[2]
	end
	-- dummy out some Redbean functions so that triggers can receive parameters and report output
	-- for example, an SSG trigger might output, say, a TAR or ZIP file via Write & report it as application/octet-stream
	-- the reason for these semantics in triggers is so that a simple 'bridge' verb can be used to execute triggers from the web UI
	local sandbox = wikiMakeEnv()
	sandbox.SetStatus = function () end
	sandbox.SetHeader = function () end
	sandbox.ServeRedirect = function () end
	sandbox.Write = function (data) options.writer(tostring(data)) end
	sandbox.GetPath = function (k) return parsedUrl.path end
	sandbox.GetParam = function (k) return params[k] end
	sandbox.GetParams = function (k) return params end
	sandbox.GetHeader = function (k) return nil end
	sandbox.GetMethod = function (k) return method end
	return sandbox
end

-- Anything that needs to happen after we have initialized funcWebWiki but before Redbean has opened the server happens here.

-- exposed to REPL
function wikiRunTrigger(v)
	Log(kLogInfo, "running trigger: " .. v)
	-- the path on this is *intentionally* left wrong
	local parsedUrl = ParseUrl(v, kUrlPlus)
	local triggerEnv = wikiMakeEnvEmuRequest({
		writer = io.write,
		url = v,
		method = "POST"
	})
	triggerEnv.dofile("system/trigger/" .. (parsedUrl.path or "") .. ".lua")
	io.flush()
end

for _, v in ipairs(scheduledTriggers) do
	wikiRunTrigger(v)
end

-- Packing is done late to allow triggers (used to setup the cache) to run before packing.
if doPack then
	assert(not assetFs.readOnly, "self-modification (-*) not enabled")
	fsTransfer(diskFs, assetFs, "packed")
	-- Someone, theoretically, may have a script which packs the wiki and then serves it...
	primaryFs = assetFs
	rebuildFSGlobals()
end

if (not doContinue) and doExit then
	os.exit(0)
end

-- report mode

if primaryFs == assetFs then
	if assetFs.readOnly then
		Log(kLogInfo, "wiki in read-only Redbean asset mode (check `-- --help` to unpack etc.)")
	else
		Log(kLogInfo, "wiki in self-modifying Redbean asset mode (scary)")
	end
elseif primaryFs.readOnly then
	Log(kLogInfo, "wiki in read-only directory mode")
else
	Log(kLogInfo, "wiki in directory mode")
end

-- Anything that touches Redbean (we have confirmed we will serve files) happens here.

if not publicUnsafe then
	ProgramAddr("127.0.0.1")
end

-- this allows kernel.lua text-search highlighting --
ProgramContentType("lua", "text/plain")

if payloadSizeOverride then
	ProgramMaxPayloadSize(payloadSizeOverride)
elseif not wikiReadOnly then
	ProgramMaxPayloadSize(0x1000000)
end

-- Redbean callbacks

function OnWorkerStart()
end

function OnHttpRequest()
	if BASIC_AUTH then
		if GetHeader("Authorization") ~= BASIC_AUTH then
			SetStatus(401)
			SetHeader("WWW-Authenticate", "Basic realm=funcWebWiki")
			return
		end
	end

	local path = GetPath()

	-- note that this takes precedence over prefix stripping
	if favicon and (path == "/favicon.ico" or path == "/robots.txt") then
		local data = primaryFs.read(path:sub(2))
		if not data then
			if (GetAssetSize(path) or 0) <= 0 then
				SetStatus(404)
				return
			else
				return RoutePath(path)
			end
		else
			Write(data)
			return
		end
	end

	if stripPrefix then
		if path:sub(1, #stripPrefix) ~= stripPrefix then
			SetStatus(404)
			return
		end
		path = "/" .. path:sub(#stripPrefix + 1)
	end

	local ewm = GetParam("_twm")
	if KEDIT_PASSWORD and (ewm == KEDIT_PASSWORD) then
		if GetMethod() == "POST" then
			local code = GetParam("code")
			if code then
				code = code:gsub("\r", "")
				wikiWrite(path, code)
			end
		end
		Write("<h2>funcWebWiki: tactical witch mode, editing: " .. EscapeHtml(path) .. "</h2>\n")
		Write("<form method=\"post\">\n")
		Write("<textarea id=\"editor\" name=\"code\" cols=80 rows=25>")
		Write(EscapeHtml(wikiRead(path)))
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

	local sandbox = wikiMakeEnv()
	if stripPrefix then
		sandbox.GetPath = function () return path end
	end
	sandbox.dofile("system/request.lua")
end
