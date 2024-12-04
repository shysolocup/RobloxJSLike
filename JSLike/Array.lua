--!strict


local config = script.Parent.Config;
local JSLikeError = require(config.Errors);

local Object = require(script.Parent.Object);


--- JSLike Array
--- @class Array
local Array = {
	__name = "Array"
};

Array.Prototype = {
	__type = Array,
	__typename = Array.__name,
	__extendees = { Object },
	__extensible = true
};


local base = {
	length = {
		__get = function(self)
			return #self;
		end,
		__writable = false,
		__configurable = false,
		__enumerable = false
	}
}


type _ArrayMeta = typeof(setmetatable({}, Array.Prototype));


export type _Array = _ArrayMeta & {
	__properties: any,
	__prototype: {[string]: any},

	-- class data
	__type: any,
	__typename: string,
	__extendees: {[number]: string} | nil,
	__extensible: boolean,

	-- magic methods
	__index: (_Array, name: string) -> any | nil,
	__newindex: (_Array, name: string, value: any) -> boolean,

	-- typechecking method
	__isA: (_Array, t: string) -> boolean,

	-- extensions
	__super: (_Array) -> nil
}



--- Creates a new Array
-- @param data Table of data to be used to create the Array
function Array.new(data: {[string]: any}): _Array
	if not data then data = {} end;

	local self = {
		__properties = {},
		__prototype = Array.Prototype,

		__type = Array.Prototype.__type,
		__typename = Array.Prototype.__typename,
		__extendees = Array.Prototype.__extendees,
		__extensible = Array.Prototype.__extensible,
	};
	
	Object.super(self, data);

	for k, v in pairs(rawget(self, "__properties")) do
		if typeof(k) ~= "number" then
			JSLikeError.throw("Array.NonIndex")
		end
	end

	self = setmetatable(self, Array.Prototype);
	
	for k, v in pairs(base) do
		Object.defineProperty(self, k, v);
	end

	return self :: _Array;
end



return Array;
