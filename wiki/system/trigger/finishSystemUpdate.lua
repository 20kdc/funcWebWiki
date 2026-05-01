-- Copies <system/newHashes.json> to <system/hashes.json>.
wikiWrite("system/hashes.json", assert(wikiRead("system/newHashes.json"), "system/newHashes.json must exist."))
return true