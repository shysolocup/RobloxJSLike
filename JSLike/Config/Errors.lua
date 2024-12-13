local JSLikeError = {};


JSLikeError.Errors = {
	["Object.Specify"] = "Invalid property descriptor. Cannot have a get/set method and a value in the same descriptor",
	["Object.NoSet"] = "Cannot set property %s of object which only has a get method and no set method",
	["Object.ReadOnly"] = "Cannot set %s of read-only object",
	["Object.NonExt"] = "Cannot extend %s from %s because %s is not extensible. (can't extend off of an object with __extensible set to false)",
	["Object.NonEnum"] = "Cannot iterate over non-enumerable object (baby version: you can't loop through an object with __enumerable set to false)",
	["Array.NonIndex"] = "Cannot create Array from dict table (eg: ❌{ key = 'value' } ✅{ 'value1', 'value2' })"
}



function JSLikeError.throw(err, ...)
	local err = "JSLikeError: "..JSLikeError.Errors[err];
	
	if #{...} > 0 then
		error(string.format(err, ...));
	else
		error(err);
	end
end


function JSLikeError.warn(err, ...)
	local err = "JSLikeError: "..JSLikeError.Errors[err];

	if #{...} > 0 then
		warn(string.format(err, ...));
	else
		warn(err);
	end
end


return JSLikeError
