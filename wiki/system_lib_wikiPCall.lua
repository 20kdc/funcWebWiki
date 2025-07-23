-- tracing pcall()
return function (fn, ...)
	return xpcall(fn, function (obj)
		if type(obj) ~= "string" then
			obj = EncodeLua(obj)
		end
		return debug.traceback(coroutine.running(), obj, 2)
	end, ...)
end
