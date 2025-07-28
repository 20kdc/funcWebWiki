-- Live preview action.
-- This is marked as a write action for a pretty simple reason:
-- It is asking the server to essentially render _whatever the requester wants._
-- This trivially includes Lua writes.

local requestPath, requestExt = ...

local code = GetBody() or ""
code = code:gsub("\r", "")

local renderer = wikiRenderer(requestExt)

wikiAST.serveRender(renderer(requestPath, code, {}, {}))
