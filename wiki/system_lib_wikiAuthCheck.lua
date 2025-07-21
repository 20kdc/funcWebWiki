-- Returns true if the request may perform this action on the given path.
return function (action, path)
	-- document.cookie = "password=ganymede"
	-- return GetCookie("password") == "ganymede"
	return true
end
