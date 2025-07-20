-- Returns true if the request may perform this action on the given path.
-- Actions that perform this check are <system/action/delete> and <system/action/edit>.
return function (action, path)
	-- document.cookie = "password=ganymede"
	-- return GetCookie("password") == "ganymede"
	return true
end