local JSLikeError = {};


JSLikeError.Errors = {
	["Object.Specify"] = "Invalid property descriptor. Cannot have a get/set method and a value in the same descriptor",
	["Object.NoSet"] = "Cannot set property %s of object which only has a get method and no set method",
	["Object.ReadOnly"] = "Cannot set %s of read-only object",
}



function JSLikeError.throw(err, ...)
	error(string.format("JSLikeError: "..JSLikeError.Errors[err], ...));
end


return JSLikeError
