--!strict

local metamethods = { "__index", "__newindex", "__add", "__sub", "__mul", "__div", "__unm", "__mod", "__pow", "__idiv", "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr", "__eq", "__lt", "__le", "__gt", "__ge", "__len", "__call", "__tostring", "__metatable", "__pairs", "__ipairs", "__iter" };
local config = script.Parent.Parent.Config;
local JSLikeError = require(config.Errors);


function clonetbl(t)
	local c = {};
	for k, v in pairs(t) do c[k] = v; end
	return c;
end



function strstarts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end


return function(Object)



--- JSLike ObjectProperty used for property descriptors
--- @class ObjectProperty
local ObjectProperty = {
	__name = "ObjectProperty"
};

ObjectProperty.Prototype = {
	__type = ObjectProperty,
	__typename = ObjectProperty.__name,
	__extendees = {},
	__extensible = true,
	__clonable = true
};




type _ObjectPropertyMeta = typeof(setmetatable({}, ObjectProperty.Prototype));



--- A type alias describing the shape of an ObjectProperty instance
export type _ObjectProperty = _ObjectPropertyMeta & {

	-- value of the property
	__value : any?,

	-- parent Object that the property is in
	__parent : Object._Object,

	-- if strict is on then it'll crash instead of just doing nothing when you piss off the 3 below this
	-- it's false by default and not technically from the js version of objects but I added it bc you can technically do it by adding "use strict" to a file
	__strict : boolean,

	-- writable is for read only objects where you can't set things inside of the value
	-- enumerable is if it can be for looped
	-- configurable is for read only objects where you can't set things inside of the descriptors
	__writable : boolean,
	__enumerable : boolean,
	__configurable : boolean,

	-- get is a function ran when a property that doesn't exist is gotten
	-- in js it runs when you get a property at all even if it exists
	-- the only reason it's different is bc lua is shit
	__get : (_ObjectProperty, name : string) -> any?,
	__set : (_ObjectProperty, name : string, value: any?) -> any?,
	__delete : (_ObjectProperty, name : string) -> any?,

	-- only available using rawget because __realvalue is changed in __index to be a combination of __get and __value
	__realvalue : (_ObjectProperty) -> any?,

	-- magic methods
	__index : (_ObjectProperty, name : string) -> any?,
	__newindex : (_ObjectProperty, name : string, value: any?) -> boolean,

	__prototype : { [string] : any },

	-- class data
	__type : any,
	__typename : string,
	__extendees : { [number] : string },
	__extensible : boolean,
	__clonable: boolean,

	-- typechecking method
	__isA : (_ObjectProperty, t : string) -> boolean,
}




--- Creates a new ObjectProperty
-- @param self An Object instance acting as a parent/owner of the ObjectProperty
-- @param data Table of data to be used to create the ObjectProperty
function ObjectProperty.new(parent : Object._Object, data : { [string] : any }? ) : _ObjectProperty
	local data = data or {};

	for _, p in {"__type", "__typename", "__extendees", "__extensible", "__clonable"} do data[p] = ObjectProperty.Prototype[p]; end
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
function ObjectProperty.Prototype.__isA(self : _ObjectProperty, t : string) : boolean
	return rawget(self, "__typename") == t;
end




function ObjectProperty.Prototype.__realvalue(self : _ObjectProperty) : any
	return rawget(self, "__value") or rawget(self, "__get")(self);
end



--- Controls how data is read inside the property
-- @param self An ObjectProperty instance, if you use metamethods you should just ignore this
-- @param name Name of the property being gotten
function ObjectProperty.Prototype.__index(self : _ObjectProperty, name : string) : any

	-- readonly value combining __value and __get
	if name == "__realvalue" then
		return ObjectProperty.Prototype.__realvalue(self);


		-- if the prototype has it then get property through that
	elseif rawget(ObjectProperty.Prototype, name) then
		return rawget(ObjectProperty.Prototype, name);  


		-- if __get exists then get the property through that
	elseif rawget(self, "__get") then 
		return rawget(self, "__get")(rawget(self, "__parent"));


		-- finally if it exists inside of the value itself
	else
		return rawget(self, "__value")[name];
	end

end



--- Controls how data is set inside the property
-- @param self An ObjectProperty instance, if you use metamethods you should just ignore this
-- @param name Name of the property being gotten
-- @param value New value of the property that's being set
function ObjectProperty.Prototype.__newindex(self : _ObjectProperty, name : string, value: any? ) : boolean

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




function ObjectProperty.Prototype.__add(self, a) return self.__realvalue + a; end
function ObjectProperty.Prototype.__sub(self, a) return self.__realvalue - a; end
function ObjectProperty.Prototype.__mul(self, a) return self.__realvalue * a; end
function ObjectProperty.Prototype.__div(self, a) return self.__realvalue / a; end
function ObjectProperty.Prototype.__unm(self, a) return -(self.__realvalue); end
function ObjectProperty.Prototype.__mod(self, a) return self.__realvalue % a; end
function ObjectProperty.Prototype.__pow(self, a) return self.__realvalue ^ a; end
function ObjectProperty.Prototype.__idiv(self, a) return self.__realvalue // a; end


-- these don't work whether it's my fault or not idk bc idk how they work

-- function ObjectProperty.Prototype.__band(self, a) return self.__realvalue & a; end
-- function ObjectProperty.Prototype.__bor(self, a) return self.__realvalue | a; end
-- function ObjectProperty.Prototype.__bxor(self, a) return self.__realvalue ^ a; end
-- function ObjectProperty.Prototype.__bnot(self) return ~self.__realvalue; end
-- function ObjectProperty.Prototype.__shl(self, a) return self.__realvalue << a; end
-- function ObjectProperty.Prototype.__shr(self, a) return self.__realvalue >> a; end



function ObjectProperty.Prototype.__eq(self, a) return self.__realvalue == a; end
function ObjectProperty.Prototype.__lt(self, a) return self.__realvalue < a; end
function ObjectProperty.Prototype.__le(self, a) return self.__realvalue <= a; end
function ObjectProperty.Prototype.__gt(self, a) return self.__realvalue > a; end
function ObjectProperty.Prototype.__ge(self, a) return self.__realvalue >= a; end


function ObjectProperty.Prototype.__len(self) return #self.__realvalue; end
function ObjectProperty.Prototype.__call(self, ...) return self.__realvalue(...); end


function ObjectProperty.Prototype.__metatable(self) return self.__realvalue.__metatable; end


function ObjectProperty.Prototype.__iter(self) return next, self.__realvalue; end
function ObjectProperty.Prototype.__pairs(self) return pairs(self.__realvalue) end
function ObjectProperty.Prototype.__ipairs(self) return ipairs(self.__realvalue) end



if not config.debug.Value then
	function ObjectProperty.Prototype.__tostring(self) return tostring(self.__realvalue); end
end



return ObjectProperty;



end