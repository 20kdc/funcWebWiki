-- Returns true if the request may perform this action on the given path.
return function (actionParsed, requestPath)
	-- document.cookie = "password=ganymede"
	-- return GetCookie("password") == "ganymede"
	return true
end
