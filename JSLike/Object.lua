--!strict



local metamethods = { "__index", "__newindex", "__add", "__sub", "__mul", "__div", "__unm", "__mod", "__pow", "__idiv", "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr", "__eq", "__lt", "__le", "__gt", "__ge", "__len", "__call", "__tostring", "__metatable", "__pairs", "__ipairs" };
local config = script.Parent.Config;


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
	__extendees = {}
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

	-- magic methods
	__index: (_Object, name: string) -> any | nil,
	__newindex: (_Object, name: string, value: any) -> boolean,

	-- typechecking method
	__isA: (_Object, t: string) -> boolean,
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
	
	-- typechecking method
	__isA: (_ObjectProperty, t: string) -> boolean,
}



--- Controls how data is read inside the property
-- @param self An ObjectProperty instance, if you use metamethods you should just ignore this
-- @param name Name of the property being gotten
function ObjectProperty.Prototype.__index(self: any, name: string): any | nil

	-- if the prototype has it then get property through that
	if rawget(ObjectProperty.Prototype, name) then
		return rawget(ObjectProperty.Prototype, name);  

	-- if __get exists then get the property through that
	elseif rawget(self, "__get") then 
		return rawget(self, "__get")(rawget(self, "__parent"), name);

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
		rawget(self, "__set")(rawget(self, "__parent"), name, value); -- tbl, property name, new value
		return true

	-- if a __set doesn't exist then set through the value
	else
		rawget(self, "__value")[name] = value;
		return true
	end

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
	
	if prop and not prop.__writable then
		if prop.__strict then
			error("JSLike error: cannot set "..name.." of read-only object")
		end
	end
	
	Object.defineProperty(self, name, {
		value = value
	});
	
	return true;
end



--- Type checking method for an Object
-- @param self An Object instance, if you use metamethods you should just ignore this
-- @param t Type string to be checked against
function Object.Prototype.__isA(self: any, t: string): boolean
	return self.__typename == t;
end



--- Type checking method for an ObjectProperty
-- @param self An ObjectProperty instance, if you use metamethods you should just ignore this
-- @param t Type string to be checked against
function ObjectProperty.Prototype.__isA(self: any, t: string): boolean
	return self.__typename == t;
end



--- Creates a new ObjectProperty
-- @param self An Object instance acting as a parent/owner of the ObjectProperty
-- @param data Table of data to be used to create the ObjectProperty
function ObjectProperty.new(parent: any, data: {[string]: any}): _ObjectProperty
	if not data then data = {} end;
	
	data.__type = ObjectProperty.Prototype.__type;
	data.__typename = ObjectProperty.Prototype.__typename;
	data.__extendees = ObjectProperty.Prototype.__extendees;
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

	data = setmetatable(data, ObjectProperty.Prototype);
	return data :: _ObjectProperty;
end



--- Creates a new property inside an Object
-- @param self An Object instance you want to add the property to
-- @param name Name of the property you want to add
-- @param data Table of data to be used to create the property
function Object.defineProperty(self: any, name: string, data: {[string]: any}): _ObjectProperty
	local prop = ObjectProperty.new(self, data);
	self.__properties[name] = prop;
	return prop;
end



--- Gets a shallow property descriptor from an Object
-- @param self Object instance to get descriptors from
-- @param name Name of the property you want to get
function Object.getOwnPropertyDescriptor(self: any, name: string): {[string]: any}
	local clone = clonetbl(self.__properties[name]);
	return clone;
end



--- Gets all shallow property descriptors from an Object
-- @param self Object instance to get descriptors from
function Object.getOwnPropertyDescriptors(self: any): {[string]: any}
	local desc = {};
	
	for k in pairs(self.__properties) do
		desc[k] = Object.getOwnPropertyDescriptor(self, k);
	end
	
	return desc
end



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
	};

	for k, v in pairs(data) do
		Object.defineProperty(self, k, {
			__value = v,
			__writable = true,
			__configurable = true,
			__enumerable = true
		});
	end

	self = setmetatable(self, Object.Prototype);

	return self :: _Object;
end




-- below this point is hell unless you want your eyes gouged out probably don't look down here




function ObjectProperty.Prototype.__add(self, a) return self.__value + a; end
function ObjectProperty.Prototype.__sub(self, a) return self.__value - a; end
function ObjectProperty.Prototype.__mul(self, a) return self.__value * a; end
function ObjectProperty.Prototype.__div(self, a) return self.__value / a; end
function ObjectProperty.Prototype.__unm(self, a) return -self.__value; end
function ObjectProperty.Prototype.__mod(self, a) return self.__value % a; end
function ObjectProperty.Prototype.__pow(self, a) return self.__value ^ a; end
function ObjectProperty.Prototype.__idiv(self, a) return self.__value // a; end


-- these don't work whether it's my fault or not idk

-- function ObjectProperty.Prototype.__band(self, a) return self.__value & a; end
-- function ObjectProperty.Prototype.__bor(self, a) return self.__value | a; end
-- function ObjectProperty.Prototype.__bxor(self, a) return self.__value ^ a; end
-- function ObjectProperty.Prototype.__bnot(self) return ~self.__value; end
-- function ObjectProperty.Prototype.__shl(self, a) return self.__value << a; end
-- function ObjectProperty.Prototype.__shr(self, a) return self.__value >> a; end



function ObjectProperty.Prototype.__eq(self, a) return self.__value == a; end
function ObjectProperty.Prototype.__lt(self, a) return self.__value < a; end
function ObjectProperty.Prototype.__le(self, a) return self.__value <= a; end
function ObjectProperty.Prototype.__gt(self, a) return self.__value > a; end
function ObjectProperty.Prototype.__ge(self, a) return self.__value >= a; end


function ObjectProperty.Prototype.__len(self) return #self.__value; end
function ObjectProperty.Prototype.__call(self, ...) return self.__value(...); end


function ObjectProperty.Prototype.__tostring(self) return tostring(self.__value); end
function ObjectProperty.Prototype.__metatable(self) return self.__value.__metatable; end
function ObjectProperty.Prototype.__pairs(self) return pairs(self.__value); end
function ObjectProperty.Prototype.__ipairs(self) return ipairs(self.__value); end



return Object;
