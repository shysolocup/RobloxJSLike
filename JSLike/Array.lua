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

	-- read-only property length returns the length of the items
	length = {
		__get = function(self)
			return #self;
		end,
		__writable = false,
		__configurable = false,
		__enumerable = false
	},


	-- read-only property __arrayitems returns an indexed array version of __properties ignoring dict entries
	__arrayitems = {
		__get = function(self)
			local arr = {};

			for k, v in pairs(rawget(self, "__properties")) do
				if typeof(k) == "number" then
					arr[k] = v;
				end
			end

			return arr;
		end,
		__writable = false,
		__configurable = false,
		__enumerable = false
	}
}



type _ArrayMeta = typeof(setmetatable({}, Array.Prototype));



--- A type alias describing the shape of an Array instance
export type _Array = _ArrayMeta & {
	
	push : (_Array, item: any?) -> Object._ObjectProperty,
	unshift : (_Array, item: any?) -> Object._ObjectProperty,
	join : (_Array, joiner : any?) -> string,
	toString : (_Array) -> string,
	at : (_Array, index : number) -> any | Object._ObjectProperty,
	indexOf: (_Array, item: string?) -> number,
	
	__properties : { [any] : Object._ObjectProperty },
	__prototype : { [string] : any },

	-- class data
	__type : any,
	__typename : string,
	__extendees : { [number] : string },
	__extensible : boolean,

	-- magic methods
	__index:  (_Array, name : string) -> any,
	__newindex : (_Array, name : string, value : any) -> boolean,

	-- typechecking method
	__isA : (_Array, t : string) -> boolean,
}



--- Creates a new Array
-- @param data Table of data to be used to create the Array
function Array.new(data : { [string]: any }? ) : _Array
	data = data or {};

	local self = {
		__properties = {},
		__prototype = Array.Prototype,,
	};

	for p in {"__type", "__typename", "__extendees", "__extensible"} do self[p] = Array.Prototype[p]; end
	
	Object.super(self, data);

	for k in pairs(rawget(self, "__properties")) do
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
function Array.Prototype.push(self : _Array, item : any? ) : Object._ObjectProperty
	if typeof(item) == "table" and item.__typename == "ObjectProperty" then
		return Object.defineProperty(self, self.length+1, item);
	else
		return Object.defineProperty(self, self.length+1, {
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
function Array.Prototype.unshift(self : _Array, item : any?) : Object._ObjectProperty
	local prop = nil;

	if typeof(item) == "table" and item.__typename == "ObjectProperty" then
		prop = item;
	else
		prop = ObjectProperty.new(self, item);
	end

	table.insert(rawget(self, "__properties"), 1, prop);
	return prop;
end



--- Joins array into a string of the array's items separated by a joiner
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param joiner The thing you want to separate the items by
function Array.Prototype.join(self : _Array, joiner : any? ) : string
	joiner = joiner or ",";

	if typeof(joiner) ~= "string" then joiner = tostring(joiner) end;
	local joined = "";
	
	local i = 0;
	
	for i, v in ipairs(self.__arrayitems) do
		i += 1;
		
		joined = joined .. tostring(v.__realvalue)
		
		if i < #values then
			joined = joined .. tostring(joiner);
		end
	end
	
	return joined;
end



--- Turns an Array into a joined string joined by commas (eg: a,b,c)
-- @param self An Array instance, if you use metamethods you should just ignore this
function Array.Prototype.toString(self : _Array) : string
	return self:join()
end



--- Returns an item from an Array at a given index using a for loop
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param index Place in the Array you want to find
function Array.Prototype.at(self : _Array, index : number): any | Object._ObjectProperty
	for i, v in ipairs(self.__arrayitems) do
		if i == index then
			return v;
		end
	end
	
	return nil;
end



--- Finds the index of a property
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param item Item you want to find the index of.
function Array.Prototype.indexOf(self : _Array, item : string? ) : number
	for i, v in ipairs(self.__arrayitems) do
		if rawget(v, "__value") == item then
			return i;
		end
	end
	return -1;
end



local function localecompare(a, b)
	a = tostring(a.N)
	b = tostring(b.N)
	local patt = '^(.-)%s*(%d+)$'
	local _,_, col1, num1 = a:find(patt)
	local _,_, col2, num2 = b:find(patt)
	if (col1 and col2) and col1 == col2 then
	   return tonumber(num1) < tonumber(num2)
	end
	return a < b
 end



--- Sorts an Array
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param compare Optional function if you want to change how it sorts
function Array.Prototype.sort(self : _Array, compare: () -> ): _Array
	return table.sort()
end


function Array.Prototype.__len(self) return #self.__arrayitems; end
function Array.Prototype.__pairs(self) return pairs(self.__arrayitems); end
function Array.Prototype.__ipairs(self) return ipairs(self.__arrayitems); end
function Array.Prototype.__iter(self) return next, self.__arrayitems; end



return Array;
