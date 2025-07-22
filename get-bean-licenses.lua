-- Attempt to extract Redbean's licenses as a show of good faith.
-- __notice
-- is the method Redbean uses to store license data.
-- Unfortunately Redbean is not able to access these notices by itself.
-- We're looking for a contiguous block that always starts with "Cosmopolitan C" and ends with "\0\0\n\n".
-- References:
-- * https://github.com/jart/cosmopolitan/blob/f1e83d52403060d674161944e849b51f95707c9a/libc/integral/c.inc#L650
-- * https://github.com/jart/cosmopolitan/blob/f1e83d52403060d674161944e849b51f95707c9a/CONTRIBUTING.md?plain=1#L72
-- * https://github.com/jart/cosmopolitan/blob/f1e83d52403060d674161944e849b51f95707c9a/ape/ape.lds#L337

local f = io.open(..., "rb")
local contents = f:read("*a")

local noticeOrder = {}
local noticeTexts = {}

local function apeNotices(at)
	while contents:sub(at, at) ~= "\0" do
		local noticeEnd = contents:find("\0", at, true)
		local noticeContent = contents:sub(at, noticeEnd - 1)
		at = noticeEnd + 1
		local noticeId = noticeContent:match("[^\n]+") or "?"
		local oldContent = noticeTexts[noticeId]
		if not oldContent then
			io.stderr:write("found NEW notice: " .. noticeId .. "\n")
			noticeTexts[noticeId] = noticeContent
			table.insert(noticeOrder, noticeId)
		else
			io.stderr:write("found notice: " .. noticeId .. "\n")
			assert(oldContent == noticeContent, "notice " .. noticeId .. " differs: [" .. oldContent .. "] -> [" .. noticeContent .. "]")
		end
	end
	io.stderr:write("end of notice block\n")
end

-- Because it's the 'libc,' the 'Cosmopolitan' base license should always be linked first. This is my best guess, anyhow; it is linked first in the 3.0.0 binary.
local start1 = contents:find("\n\nCosmopolitan\nCopyright", 1, true)
apeNotices(start1)
-- There's a second set of notices; I believe these are for the ARM64 version. Include these also, or compiler_rt gets missed.
local start2 = contents:find("XYZ[\\]^", start1, true)
local start3 = contents:find("\n\n[a-zA-Z]", start2)
apeNotices(start3)

print("This file contains the license notices found within Redbean, retrieved by get-bean-licenses.lua in the funcWebWiki repository.")
print("The source code to Redbean and these dependencies appears to be held in the monolithic https://github.com/jart/cosmopolitan repository.")
print("As a Redbean binary does not contain the license text as required by many of these licenses, the following acknowledgements are made:")
local acknowledged = {
	["Cosmopolitan"] = "license shipped in Redbean",
	["largon2 (MIT License)"] = "no license conditions shipped - mit-license.txt is shipped as a good-faith effort",
	["lsqlite3 (MIT License)"] = "lsqlite3.txt",
	["TRE regex (BSD-2 License)"] = "tre.txt",
	["libmaxminddb (Apache 2.0)"] = "maxmind.txt",
	["Lua 5.4.6 (MIT License)"] = "lua.txt",
	["double-conversion (BSD-3 License)"] = "double-conversion.txt",
	["Cosmopolitan Linenoise (BSD-2)"] = "linenoise.txt",
	["getopt (BSD-3)"] = "getopt.txt",
	["argon2 (CC0 or Apache2)"] = "argon2.txt",
	["Cosmopolitan Everest (Apache 2.0)"] = "everest.txt",
	["Mbed TLS (Apache 2.0)"] = "mbedtls/LICENSE is the Apache 2 license verbatim; see mbedtls.txt and apache2-license.txt",
	["zlib 1.2.13 (zlib License)"] = "Cosmopolitan uses a Chromium zlib and possibly more modifications. General licenses are in zlib.txt",
	["gdtoa (MIT License)"] = "gdtoa.txt",
	["OpenBSD Sorting (BSD-3)"] = "opensort.txt - refer to https://github.com/jart/cosmopolitan/blob/redbean-3.0.0/libc/mem/mergesort.c",
	["puff (zlib License)"] = "Cosmopolitan libc seems to have altered the source a little (formatting?). General license is in puff.txt",
	["*NSYNC (Apache 2.0)"] = "See nsync.txt ; LICENSE.txt is verbatim Apache 2, see apache2-license.txt",
	-- I would like to mention just off-hand that the blake2 in the argon2 source could have been used here.
	["boringssl blake2b (ISC License)"] = "blake2.txt",
	["HighwayHash (Apache 2.0)"] = "highwayhash.txt",
	["Smoothsort (MIT License)"] = "smoothsort.txt",
	["timingsafe_memcmp (ISC License)"] = "timingsafe_memcmp.txt",
	["OpenBSD Strings (ISC)"] = "openbsdstrings.txt (based on https://github.com/jart/cosmopolitan/blob/f1e83d52403060d674161944e849b51f95707c9a/libc/str/strlcpy.c )",
	["Optimized Routines (MIT License)"] = "optimized-routines.txt",
	["Chromium (BSD-3 License)"] = "This was eventually tracked down to third_party/zlib/adler32_simd.c and related. It is therefore covered by Redbean's copyright notice (for year) and by zlib.txt (for text).",
	-- Notably, this license notice is _slightly_ different to, say, TRE's BSD-2; check the wording "in this position and unchanged" in libelftc-demangle.
	["Cosmopolitan libelftc demangle (BSD-2)"] = "libelftc-demangle.txt",
	["FreeBSD libm (BSD-2 License)"] = "tinymath-openbsd.txt, freebsd-libm-erfc.txt (from cosmopolitan/libc/tinymath/erfc.c ) and freebsd-libm-cbrtl.txt (from cosmopolitan/libc/tinymath/cbrtl.c ); many overlapping copyright notices are here.",
	["fdlibm (fdlibm license)"] = "fdlibm.txt",
	["Musl libc (MIT License)"] = "musl.txt",
	["AVX2 SHA-1 (BSD-3 License)nCopyright 2014 Intel Corporation"] = "avx2-sha1.txt",
	["Intel SHA-NI (BSD-3 License)"] = "avx2-sha1.txt ; the updated year is given in this file",
	["AVX2 SHA2 (BSD-2 License)"] = "avx2-sha256.txt",
	["AVX2 SHA512 (BSD-2 License)"] = "avx2-sha512.txt",
	-- ARM64(?)
	["compiler_rt (Licensed \"University of Illinois/NCSA Open Source License\")"] = "compiler-rt.txt"
}
for _, k in ipairs(noticeOrder) do
	assert(acknowledged[k], k)
	print("\t" .. k .. ": " .. acknowledged[k])
end
print()
for _, k in ipairs(noticeOrder) do
	print(noticeTexts[k])
end
print()
print()
