local JSLikeError = {};


JSLikeError.Errors = {
	["Object.Specify"] = "Invalid property descriptor. Cannot have a get/set method and a value in the same descriptor",
	["Object.NoSet"] = "Cannot set property %s of object which only has a get method and no set method",
	["Object.ReadOnly"] = "Cannot set %s of read-only object",
	["Object.NonExt"] = "Cannot extend %s from %s because %s is not extendable."
}



function JSLikeError.throw(err, ...)
	local err = "JSLikeError: "..JSLikeError.Errors[err];
	
	if #{...} > 0 then
		error(string.format(err, ...));
	else
		error(err);
	end
end


return JSLikeError
