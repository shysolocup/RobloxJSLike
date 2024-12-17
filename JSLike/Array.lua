--!strict




local config = script.Parent.Config;
local JSLikeError = require(config.Errors);

local Object = require(script.Parent.Object);
local ObjectProperty = Object.ObjectProperty;



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
			return rawget(self, "__len")(self);
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
				if typeof(k) == "number" and rawget(v, "__enumerable") then
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

	length : number,
	__arrayitems : { [number] : Object._ObjectProperty },

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
	local data = data or {};

	local self = {
		__properties = {},
		__prototype = Array.Prototype,
	};

	for _, p in {"__type", "__typename", "__extendees", "__extensible", "__clonable"} do self[p] = Array.Prototype[p]; end

	Object.super(self, data);

	for k in pairs(rawget(self, "__properties")) do
		if typeof(k) ~= "number" then
			JSLikeError.throw("Array.NonIndex")
		end
	end

	setmetatable(self, Array.Prototype);

	for k, v in pairs(base) do
		Object.defineProperty(self, k, v);
	end

	return self :: _Array;
end



--- Adds a new item to the Array at the given index pushing everything else back
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param item Item you want to insert.
-- @param index Index you want to insert at, if not given removes the last index
function Array.Prototype.insert(self : _Array, item : any?, index : number? ) : Object._ObjectProperty
	Object.hasIdentity(self);
	local index = index or #self+1;
	
	local t = {};
	
	for i=1, (#self.__arrayitems)+1 do
		if i == index then
			t[i] = ObjectProperty.new(self, Object.defaults({
				value = item;
			}))
		elseif i > index then
			t[i] = self:at(i-1);
		elseif i < index then
			t[i] = self:at(i);
		end
	end
	
	for i, v in t do
		rawget(self, "__properties")[i] = v;
	end
	
	return self:at(index);
end



--- Adds a new item to the end of the Array
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param item Item you want to push.
function Array.Prototype.push(self : _Array, item : any? ) : Object._ObjectProperty
	return self:insert(item);
end




--- Adds a new item to the beginning of the Array
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param item Item you want to unshift.
function Array.Prototype.unshift(self : _Array, item : any?) : Object._ObjectProperty
	return self:insert(item, 1);
end



--- Removes an item in the Array pushing everything else back
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param index Index you want to delete, if not given removes the last index
function Array.Prototype.unsert(self : _Array, index : number? ) : Object._ObjectProperty
	Object.hasIdentity(self);
	local index = index or #self+1;

	local old = self:at(index);
	
	local t = {};
	
	for i=1, (#self.__arrayitems)-1 do
		if i > index then
			t[i-1] = self:at(i);
		elseif i < index then
			t[i] = self:at(i);
		end
	end

	for i, v in t do
		rawget(self, "__properties")[i] = v;
	end

	Object.delete(self, (#self.__arrayitems));
	
	return old;
end



--- Removes the last item in the Array
-- @param self An Array instance, if you use metamethods you should just ignore this
function Array.Prototype.pop(self : _Array) : Object._ObjectProperty
	Object.hasIdentity(self);
	return self.unset(self)
end



--- Removes the first item in the Array
-- @param self An Array instance, if you use metamethods you should just ignore this
function Array.Prototype.shift(self : _Array) : Object._ObjectProperty
	Object.hasIdentity(self);
	return self.unset(self, 1);
end



--- Joins array into a string of the array's items separated by a joiner
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param joiner The thing you want to separate the items by
function Array.Prototype.join(self : _Array, joiner : any? ) : string
	Object.hasIdentity(self);

	local joiner = tostring(joiner) or ",";
	local joined = "";

	local i = 0;
	local values = self.__arrayitems;

	for _, v in values do
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
	Object.hasIdentity(self);

	return self:join()
end



--- Returns an item from an Array at a given index using a for loop
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param index Place in the Array you want to find
function Array.Prototype.at(self : _Array, index : number): any | Object._ObjectProperty
	Object.hasIdentity(self);

	for i, v in self.__arrayitems do
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
	Object.hasIdentity(self);

	for i, v in self.__arrayitems do
		if rawget(v, "__value") == item then
			return i;
		end
	end

	return -1;
end




--- Goes through every entry in the Array
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param callback Callback function passing v (value) and i (index)
function Array.Prototype.forEach(self : _Array, callback: (v : any?, i : number) -> any? )
	Object.hasIdentity(self);

	for i, v in self.__arrayitems do
		callback(v, i);
	end
end



--- Goes through every entry in the Array changing each value depending on what's returned
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param callback Callback function passing v (value) and i (index)
function Array.Prototype.map(self : _Array, callback: (v : any?, i : number) -> any ): _Array
	Object.hasIdentity(self);
	local clone = Object.clone(self);

	for i, v in clone.__arrayitems do
		if rawget(v, "__writable") then
			Object.writeProperty(self, i, {
				__value = callback(v, i)
			});
		end
	end
end



--- Sorts an Array
-- @param self An Array instance, if you use metamethods you should just ignore this
-- @param compare Optional function if you want to change how it sorts
--[[function Array.Prototype.sort(self : _Array, compare: (a : any, b : any) -> any): _Array
	return 
end]]


function Array.Prototype.__len(self) return #self.__arrayitems; end



if not config.debug.Value then
	function Array.Prototype.__tostring(self, depth : number?) 
		local props = rawget(self, "__properties");
		return typeof(props) == "table" and Object.stringify(props, {"[","]"}, false, depth) or tostring(props); 
	end
end



return Array;
