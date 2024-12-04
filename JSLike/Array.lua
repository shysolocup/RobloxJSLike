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



--- A little table for base properties inside of the Array class
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



--- A type alias describing the shape of an Array instance
export type _Array = _ArrayMeta & {
	
	join: (_Array, joiner: any) -> string,
	toString: (_Array) -> string,
	at: (_Array, index: number) -> any | Object._ObjectProperty,
	
	__properties: {[any]: Object._ObjectProperty},
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



--- Adds a new item to the end of the Array
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param item Item you want to push. If you put an ObjectProperty it'll define it using that
function Array.Prototype.push(self: _Array, item: any | nil): boolean
	if typeof(item) == "table" and item.__typename == "ObjectProperty" then
		Object.defineProperty(self, self.length+1, item);
	else
		Object.defineProperty(self, self.length+1, {
			__value = item,
			__writable = true,
			__configurable = true,
			__enumerable = true
		})
	end
end




--- Adds a new item to the beginning of the Array
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param item Item you want to unshift. If you put an ObjectProperty it'll define it using that
function Array.Prototype.unshift(self: _Array, item: any | nil): boolean
	local prop = nil;

	if typeof(item) == "table" and item.__typename == "ObjectProperty" then
		prop = item;
	else
		prop = ObjectProperty.new(self, item);
	end

	table.insert(rawget(self, "__properties"), 1, prop);
end



--- Joins array into a string of the array's items separated by a joiner
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param joiner The thing you want to separate the items by
function Array.Prototype.join(self: _Array, joiner: any | nil): string
	if not joiner then joiner = ","; end
	if typeof(joiner) ~= "string" then joiner = tostring(joiner) end;
	local joined = "";
	local values = Object.values(self, base);
	
	local i = 0;
	
	for _, v in pairs(values) do
		i += 1;
		
		joined = joined .. tostring(v)
		
		if i < #values then
			joined = joined .. tostring(joiner);
		end
	end
	
	return joined;
end



--- Turns an Array into a joined string joined by commas (eg: a,b,c)
-- @param self An Array instance, if you use metamethods you should just ignore this
function Array.Prototype.toString(self: _Array): string
	return self:join(",")
end



--- Returns an item from an Array at a given index using a for loop
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param index Place in the Array you want to find
function Array.Prototype.at(self: _Array, index: number): any | nil
	for i, v in ipairs(rawget(self, "__properties")) do
		if i == index then
			return v;
		end
	end
	
	return nil;
end



return Array;
