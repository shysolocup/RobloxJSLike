--!strict



local metamethods = { "__index", "__newindex", "__add", "__sub", "__mul", "__div", "__unm", "__mod", "__pow", "__idiv", "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr", "__eq", "__lt", "__le", "__gt", "__ge", "__len", "__call", "__tostring", "__metatable", "__pairs", "__ipairs" };
local config = script.Parent.Config;
local JSLikeError = require(config.Errors);


function clonetbl(t)
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end



function strstarts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end



--- JSLike Object used for object stuff
--- @class Object
local Object = {
	__name = "Object"
};



Object.Prototype = {
	__type = Object,
	__typename = Object.__name,
	__extendees = {},
	__extensible = true
};



--- JSLike ObjectProperty used for property descriptors
--- @class ObjectProperty
local ObjectProperty = {
	__name = "ObjectProperty"
};

ObjectProperty.Prototype = {
	__type = ObjectProperty,
	__typename = ObjectProperty.__name,
	__extendees = {},
	__extensible = true
};



type _ObjectMeta = typeof(setmetatable({}, Object.Prototype));
type _ObjectPropertyMeta = typeof(setmetatable({}, ObjectProperty.Prototype));



--- A type alias describing the shape of an Object instance
export type _Object = _ObjectMeta & {
	__properties: any,
	__prototype: {[string]: any},

	-- class data
	__type: any,
	__typename: string,
	__extendees: {[number]: string} | nil,
	__extensible: boolean,

	-- magic methods
	__index: (_Object, name: string) -> any | nil,
	__newindex: (_Object, name: string, value: any) -> boolean,

	-- typechecking method
	__isA: (_Object, t: string) -> boolean,

	-- extensions
	__super: (_Object) -> nil
}



--- A type alias describing the shape of an ObjectProperty instance
export type _ObjectProperty = _ObjectPropertyMeta & {

	-- value of the property
	__value: any | nil,

	-- parent Object that the property is in
	__parent: any | nil,

	-- if strict is on then it'll crash instead of just doing nothing when you piss off the 3 below this
	-- it's false by default and not technically from the js version of objects but I added it bc you can technically do it by adding "use strict" to a file
	__strict: boolean,

	-- writable is for read only objects where you can't set things inside of the value
	-- enumerable is if it can be for looped
	-- configurable is for read only objects where you can't set things inside of the descriptors
	__writable: boolean,
	__enumerable: boolean,
	__configurable: boolean,

	-- get is a function ran when a property that doesn't exist is gotten
	-- in js it runs when you get a property at all even if it exists
	-- the only reason it's different is bc lua is shit
	__get: nil | (_ObjectProperty, name: string) -> any | nil,
	__set: nil | (_ObjectProperty, name: string, value: any) -> any | nil,
	__delete: nil | (_ObjectProperty, name: string) -> any | nil,

	-- magic methods
	__index: (_ObjectProperty, name: string) -> any | nil,
	__newindex: (_ObjectProperty, name: string, value: any) -> boolean,

	__prototype: {[string]: any},

	-- class data
	__type: any,
	__typename: string,
	__extendees: {[number]: string} | nil,
	__extensible: boolean,

	-- typechecking method
	__isA: (_ObjectProperty, t: string) -> boolean,
}



--- Creates a new Object
-- @param data Table of data to be used to create the Object
function Object.new(data: {[string]: any}): _Object
	if not data then data = {} end;

	local self = {
		__properties = {},
		__prototype = Object.Prototype,

		__type = Object.Prototype.__type,
		__typename = Object.Prototype.__typename,
		__extendees = Object.Prototype.__extendees,
		__extensible = Object.Prototype.__extensible,
	};

	for k, v in pairs(data) do
		if typeof(v) == "table" and v.__typename == "ObjectProperty" then
			rawget(self, "__property")[k] = v;
		else
			Object.defineProperty(self, k, {
				__value = v,
				__writable = true,
				__configurable = true,
				__enumerable = true
			});
		end
	end

	self = setmetatable(self, Object.Prototype);

	return self :: _Object;
end



--- Controls how data is gotten from Objects
-- @param self An Object instance, if you use metamethods you should just ignore this
-- @param name Name of the property being gotten
function Object.Prototype.__index(self: any, name: string): any | nil

	-- if it exists in prototype then it has priority over properties
	if rawget(self, "__prototype")[name] then
		return rawget(self, "__prototype")[name];

		-- if it exists in properties get from there
	elseif rawget(self, "__properties")[name] then
		return rawget(self, "__properties")[name];

	else
		return nil;
	end

end



--- Controls how data is set in Objects
-- @param self An Object instance, if you use metamethods you should just ignore this
-- @param name Name of the property being gotten
-- @param value New value of the property that's being set
function Object.Prototype.__newindex(self: any, name: string, value: any): boolean

	local props = rawget(self, "__properties");
	local prop = props[name];

	-- if it's not writable then crash if on strict and warn if not
	if prop and not rawget(prop, "__writable") then
		if rawget(prop, "__strict") then
			JSLikeError.throw("Object.ReadOnly", name)
		else
			return JSLikeError.warn("Object.ReadOnly", name);
		end
	end
	
	-- if it has a get but no set then crash if on strict mode and just warn if not
	if prop and rawget(prop, "__get") then
		if not rawget(prop, "__set") then
			if rawget(prop, "__strict") then
				JSLikeError.throw("Object.NoSet", name);
			else	
				return JSLikeError.warn("Object.NoSet", name);
			end
		end
	end

	-- define the property :3
	Object.defineProperty(self, name, {
		value = value
	});

	return true;
end



--- Type checking method for an Object
-- @param self An Object instance, if you use metamethods you should just ignore this
-- @param t Type string to be checked against
function Object.Prototype.__isA(self: any, t: string): boolean
	return rawget(self, "__typename") == t;
end



--- Creates a new property inside an Object
-- @param self An Object instance you want to add the property to
-- @param name Name of the property you want to add
-- @param data Table of data to be used to create the property
function Object.defineProperty(self: any, name: string, data: {[string]: any}): _ObjectProperty
	local prop = ObjectProperty.new(self, data);
	rawget(self, "__properties")[name] = prop;
	return prop;
end



--- Creates new properties inside an Object
-- @param self An Object instance you want to add the properties to
-- @param properties Table of properties to be used to create properties: { [name] = { [descriptor] = [any] } }
function Object.defineProperties(self: any, properties: {[string]: any}): nil
	for name, data in pairs(properties) do
		local prop = ObjectProperty.new(self, data);
		rawget(self, "__properties")[name] = prop;
	end

	return
end



--- Gets a shallow property descriptor from an Object
-- @param self Object instance to get descriptors from
-- @param name Name of the property you want to get
function Object.getOwnPropertyDescriptor(self: any, name: string): {[string]: any}
	local clone = clonetbl(rawget(self, "__properties")[name]);
	return clone;
end



--- Gets all shallow property descriptors from an Object
-- @param self Object instance to get descriptors from
function Object.getOwnPropertyDescriptors(self: any): {[string]: any}
	local desc = {};

	for k in pairs(rawget(self, "__properties")) do
		desc[k] = Object.getOwnPropertyDescriptor(self, k);
	end

	return desc
end



--- Assigns variables from on Object or Table to an Object
-- @param self Object instance to assign variables to
-- @param ... Objects or Tables to assign variables from
function Object.assign(self: any, ...): boolean
	for _, assignee in pairs({...}) do
		if typeof(assignee) == "table" and assignee.__typename == "Object" then
			assignee = rawget(assignee, "__properties");
		end
		
		for k, v in pairs(assignee) do
			if typeof(v) == "table" and v.__typename == "ObjectProperty" then
				rawget(self, "__properties")[k] = v;
			else
				Object.defineProperty(self, k, {
					__value = v,
					__writable = true,
					__configurable = true,
					__enumerable = true
				});
			end
		end
	end
	
	return true
end



--- Assigns variables from on Object or Table to an Object without overwriting existing variables
-- @param self Object instance to assign variables to
-- @param ... Objects or Tables to assign variables from
function Object.assignNoOverwrite(self: any, ...): boolean
	for _, assignee in pairs({...}) do
		if typeof(assignee) == "table" and assignee.__typename == "Object" then
			assignee = rawget(assignee, "__properties");
		end

		for k, v in pairs(assignee) do
			if not rawget(self, "__properties")[k] then
				if typeof(v) == "table" and v.__typename == "ObjectProperty" then
					rawget(self, "__properties")[k] = v;
				else
					Object.defineProperty(self, k, {
						__value = v,
						__writable = true,
						__configurable = true,
						__enumerable = true
					});
				end
			end
		end
	end

	return true
end



--- Applies extendees
-- @param self An Object instance, if you use metamethods you should just ignore this
-- @param ... Arguments you want to run the extendees with
function Object.super(self: any, ...): nil
	for i, ext in pairs(rawget(self, "__extendees")) do
		if not ext.Prototype.__extensible then
			if config.strict.Value then
				JSLikeError.throw("Object.NonExt", rawget(self, "__typename"), ext.__typename, ext.__typename);
			else
				JSLikeError.warn("Object.NonExt", rawget(self, "__typename"), ext.__typename, ext.__typename);
			end
		else
			
			local new = ext.new(...);
			
			Object.assignNoOverwrite(self, new);
			
			for k, v in pairs(ext.Prototype) do
				if not rawget(self, "__prototype")[k] then
					rawget(self, "__prototype")[k] = v;
				end
			end
		end
	end

	return;
end



--- Gets entries in the object and puts them in a list
-- @param self An Object instance
function Object.entries(self: any): {[number]: any}
	local entries = {};

	for k, v in pairs(rawget(self, "__properties")) do
		table.insert(entries, {
			k, v.__me
		});
	end

	return entries;
end


--- Gets keys in the object and puts them into a list
-- @param self An Object instance
function Object.keys(self: any): {[number]: any}
	local keys = {};

	for k, v in pairs(rawget(self, "__properties")) do
		table.insert(keys, k);
	end

	return keys;
end



--- Gets values in the object and puts them into a list
-- @param self An Object instance
function Object.values(self: any): {[number]: any}
	local values = {};

	for k, v in pairs(rawget(self, "__properties")) do
		table.insert(values, v.__me);
	end

	return values;
end



--- Prevents new properties from being added to an object, and prevents existing properties from being removed or modified. Returns the object
-- @param self An Object instance
function Object.freeze(self: any): any
	table.freeze(rawget(self, "__properties"));
	return self;
end



--- Checks if the object is frozen or not
-- @param self An Object instance
function Object.isFrozen(self: any): boolean
	return table.isfrozen(rawget(self, "__properties"))
end



--- Checks if the object is extensible or not
-- @param self An Object instance
function Object.isExtensible(self: any): boolean
	return rawget(self, "__extensible");
end



function Object.Prototype.__len(self) return #rawget(self, "__properties"); end




--- Creates a new ObjectProperty
-- @param self An Object instance acting as a parent/owner of the ObjectProperty
-- @param data Table of data to be used to create the ObjectProperty
function ObjectProperty.new(parent: any, data: {[string]: any}): _ObjectProperty
	if not data then data = {} end;

	data.__type = ObjectProperty.Prototype.__type;
	data.__typename = ObjectProperty.Prototype.__typename;
	data.__extendees = ObjectProperty.Prototype.__extendees;
	data.__extensible = ObjectProperty.Prototype.__extensible;
	data.__prototype = ObjectProperty.Prototype;

	local datafix = {};

	for k, v in pairs(data) do
		if not strstarts(k, "__") then k = "__"..k; end
		datafix[k] = v;
	end

	data = datafix;

	local base = {
		__value = nil,
		__strict = config.strict.Value,

		__writable = false,
		__configurable = false,
		__enumerable = false,

		__get = nil,
		__set = nil,
		__delete = nil,

		__parent = parent,
	};

	for k, v in pairs(base) do
		if not data[k] then data[k] = v; end
	end

	if (data.__get or data.__set) and data.__value then
		JSLikeError.throw("Object.Specify");
	end

	data = setmetatable(data, ObjectProperty.Prototype);
	return data :: _ObjectProperty;
end



--- Type checking method for an ObjectProperty
-- @param self An ObjectProperty instance, if you use metamethods you should just ignore this
-- @param t Type string to be checked against
function ObjectProperty.Prototype.__isA(self: any, t: string): boolean
	return rawget(self, "__typename") == t;
end



--- Controls how data is read inside the property
-- @param self An ObjectProperty instance, if you use metamethods you should just ignore this
-- @param name Name of the property being gotten
function ObjectProperty.Prototype.__index(self: any, name: string): any | nil

	-- if the prototype has it then get property through that
	if rawget(ObjectProperty.Prototype, name) then
		return rawget(ObjectProperty.Prototype, name);  


	-- if __get exists then get the property through that
	elseif rawget(self, "__get") then 
		return rawget(self, "__get")(rawget(self, "__parent"));


	-- if you want to get the __me value
	elseif name == "__me" then
		if rawget(self, "__value") then return rawget(self, "__value");
			
		elseif rawget(self, "__get") then return rawget(self, "__get")(rawget(self, "__parent"));
			
		else return rawget(self, "__value")[name]; end


	-- finally if it exists inside of the value itself
	else
		return rawget(self, "__value")[name];
	end

end



--- Controls how data is set inside the property
-- @param self An ObjectProperty instance, if you use metamethods you should just ignore this
-- @param name Name of the property being gotten
-- @param value New value of the property that's being set
function ObjectProperty.Prototype.__newindex(self: any, name: string, value: any | nil): boolean

	-- if a __set value exists set through that
	if rawget(self, "__set") then
		rawget(self, "__set")(rawget(self, "__parent"), value); -- tbl, property name, new value
		return true

		-- if a __set doesn't exist then set through the value
	elseif rawget(self, "__value") then
		rawget(self, "__value")[name] = value;
		return true

		-- if it doesn't have a __set or a __value then throw error if on strict
	else
		if rawget(self, "__strict") then
			JSLikeError.throw("Object.NoSet", name);
		else
			JSLikeError.warn("Object.NoSet", name);
		end

		return false;
	end

end



-- below this point is hell unless you want your eyes gouged out probably don't look down here




function ObjectProperty.Prototype.__add(self, a) return self.__me + a; end
function ObjectProperty.Prototype.__sub(self, a) return self.__me - a; end
function ObjectProperty.Prototype.__mul(self, a) return self.__me * a; end
function ObjectProperty.Prototype.__div(self, a) return self.__me / a; end
function ObjectProperty.Prototype.__unm(self, a) return -self.__me; end
function ObjectProperty.Prototype.__mod(self, a) return self.__me % a; end
function ObjectProperty.Prototype.__pow(self, a) return self.__me ^ a; end
function ObjectProperty.Prototype.__idiv(self, a) return self.__me // a; end


-- these don't work whether it's my fault or not idk

-- function ObjectProperty.Prototype.__band(self, a) return self.__me & a; end
-- function ObjectProperty.Prototype.__bor(self, a) return self.__me | a; end
-- function ObjectProperty.Prototype.__bxor(self, a) return self.__me ^ a; end
-- function ObjectProperty.Prototype.__bnot(self) return ~self.__me; end
-- function ObjectProperty.Prototype.__shl(self, a) return self.__me << a; end
-- function ObjectProperty.Prototype.__shr(self, a) return self.__me >> a; end



function ObjectProperty.Prototype.__eq(self, a) return self.__me == a; end
function ObjectProperty.Prototype.__lt(self, a) return self.__me < a; end
function ObjectProperty.Prototype.__le(self, a) return self.__me <= a; end
function ObjectProperty.Prototype.__gt(self, a) return self.__me > a; end
function ObjectProperty.Prototype.__ge(self, a) return self.__me >= a; end


function ObjectProperty.Prototype.__len(self) return #self.__me; end
function ObjectProperty.Prototype.__call(self, ...) return self.__me(...); end


function ObjectProperty.Prototype.__metatable(self) return self.__me.__metatable; end
function ObjectProperty.Prototype.__pairs(self) return pairs(self.__me); end
function ObjectProperty.Prototype.__ipairs(self) return ipairs(self.__me); end



return Object;
