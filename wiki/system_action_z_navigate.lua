-- This action is a little bit of a kludge.
-- It's used by the 'Go' button in <system/templates/frame>.
ServeRedirect(302, wikiAbsoluteBase .. tostring(GetParam("to") or ""))