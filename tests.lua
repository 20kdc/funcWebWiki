print("funcWebWiki test battery: loading kernel...")
arg = {}
argv = arg
-- kickstart the reactor --
load(LoadAsset("kernel.lua"))(...)
-- test... --
local function runTest(name, reqRes, options)
	print("-- " .. name .. " --")
	local res = ""
	if type(options) == "string" then
		options = { url = options }
	end
	options.writer = function (v) res = res .. v end
	local emu = wikiMakeEnvEmuRequest(options)
	emu.dofile("system/request.lua")
	if reqRes then
		if res ~= reqRes then
			error("[FAIL] (result mismatch)")
		end
	end
	print("[OK]")
end

-- critical UI checks
runTest("index page doesn't fail immediately", nil, "/")
runTest("stylesheet.css should be accurate when requested raw", Slurp("wiki/system/stylesheet.css") or "Slurp failed", "/system/stylesheet.css?action=raw")

-- page creation test
runTest("opening __TEST_PAGE edit page should succeed", nil, {
	method = "GET",
	url = "/__TEST_PAGE?action=edit",
	params = { disableErrorIsolation = "1" }
})
runTest("creating the page __TEST_PAGE should succeed", nil, {
	method = "POST",
	url = "/__TEST_PAGE?action=edit",
	params = {
		code = "This is test text.",
		confirm = "1",
		disableErrorIsolation = "1",
	}
})
runTest("checking the page __TEST_PAGE is present", "This is test text.", "/__TEST_PAGE?action=raw")
runTest("deleting the page __TEST_PAGE should succeed", nil, {
	method = "POST",
	url = "/__TEST_PAGE?action=delete",
	params = {
		confirm = "1",
		disableErrorIsolation = "1",
	}
})
runTest("checking the page __TEST_PAGE is gone", "", "/__TEST_PAGE?action=raw")

-- page upload test
runTest("opening __TEST.png edit page should succeed", nil, {
	method = "GET",
	url = "/__TEST.png?action=edit",
	params = { disableErrorIsolation = "1" }
})
runTest("uploading __TEST.png should succeed", nil, {
	method = "POST",
	url = "/__TEST.png?action=edit",
	params = {
		file = "data:base64," .. EncodeBase64("The words"),
		confirm = "1",
		disableErrorIsolation = "1",
	}
})
runTest("checking __TEST.png is present", "The words", "/__TEST.png?action=raw")
runTest("deleting __TEST.png should succeed", nil, {
	method = "POST",
	url = "/__TEST.png?action=delete",
	params = {
		confirm = "1",
		disableErrorIsolation = "1",
	}
})

os.exit(0)
