-- This action is used by the 'Go' button in <system/templates/frame>.
ServeRedirect(302, wikiAbsoluteBase .. tostring(GetParam("to") or ""))