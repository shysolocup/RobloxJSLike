--!strict



local metamethods = { "__index", "__newindex", "__add", "__sub", "__mul", "__div", "__unm", "__mod", "__pow", "__idiv", "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr", "__eq", "__lt", "__le", "__gt", "__ge", "__len", "__call", "__tostring", "__metatable", "__pairs", "__ipairs", "__iter" };
local config = script.Parent.Config;
local JSLikeError = require(config.Errors);


function clonetbl(t)
	local c = {};
	for k, v in pairs(t) do c[k] = v; end
	return c;
end



function pad(o : string, t : string, l : number)
	local x = o;
	x = (t):rep(l-x:len())..x;
	return x;
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
	__extensible = true,
	__clonable = true
};


local ObjectProperty = require(script.ObjectProperty)(Object);
Object.ObjectProperty = ObjectProperty;



type _ObjectMeta = typeof(setmetatable({}, Object.Prototype));



--- A type alias describing the shape of an Object instance
export type _Object = _ObjectMeta & {
	__properties : { [any] : ObjectProperty._ObjectProperty },
	__prototype : { [string] : any },

	-- class data
	__type : any,
	__typename : string,
	__extendees : { [number] : string }?,
	__extensible : boolean,
	__clonable: boolean,

	-- magic methods
	__index : (_Object, name : string) -> any,
	__newindex : (_Object, name : string, value : any?) -> boolean,

	-- typechecking method
	__isA: (_Object, t : string) -> boolean,
}


--- Default values for an Object
-- @param overrides Overriding table with info you want to put in over the default
function Object.defaults(overrides : { [string] : any }?) : { [string] : any }
	local overrides = overrides or {};

	for k, v in pairs({
		__writable = true,
		__configurable = true,
		__enumerable = true
	}) do
		overrides[k] = overrides[k] or v;
	end

	return overrides;
end



--- Creates a new Object
-- @param data Table of data to be used to create the Object
function Object.new(data : { [any] : any }? ) : _Object
	local data = data or {};

	local self = {
		__properties = {},
		__prototype = Object.Prototype,
	};

	for _, p in {"__type", "__typename", "__extendees", "__extensible", "__clonable"} do self[p] = Object.Prototype[p]; end

	for k, v in pairs(data) do
		if typeof(v) == "table" and v.__typename == "ObjectProperty" then
			Object.defineProperty(self, k, Object.defaults({
				__value = v.__realvalue
			}));
		else
			Object.defineProperty(self, k, Object.defaults({
				__value = v,
			}));
		end
	end

	self = setmetatable(self, Object.Prototype);

	return self :: _Object;
end



--- Controls how data is gotten from Objects
-- @param self An Object instance, if you use metamethods you should just ignore this
-- @param name Name of the property being gotten
function Object.Prototype.__index(self : _Object, name : string) : any
	return rawget(self, "__prototype")[name] or rawget(self, "__properties")[name]
end



--- Controls how data is set in Objects
-- @param self An Object instance, if you use metamethods you should just ignore this
-- @param name Name of the property being gotten
-- @param value New value of the property that's being set
function Object.Prototype.__newindex(self : _Object, name : string, value : any? ) : boolean
	local props = rawget(self, "__properties");
	local prop = props[name];


	-- if it's not writable then crash if on strict and warn if not
	if prop and not rawget(prop, "__writable") then
		if rawget(prop, "__strict") then
			JSLikeError.throw("Object.ReadOnly", name)
		else
			JSLikeError.warn("Object.ReadOnly", name);
		end
		return false;
	end


	-- if it's deleting then run the __delete method
	if value == nil and (prop and rawget(prop, "__delete")) then
		rawget(prop, "__delete")(self);
		return true
	elseif value == nil and prop and not rawget(prop, "__delete") then
		rawget(self, "__properties")[name] = nil;
		prop.__parent = nil;
		return true;
	end


	-- if it has a get but no set then crash if on strict mode and just warn if not
	if prop and rawget(prop, "__get") then
		if not rawget(prop, "__set") then
			if rawget(prop, "__strict") then
				JSLikeError.throw("Object.NoSet", name);
			else	
				JSLikeError.warn("Object.NoSet", name);
			end

			return false;
		else
			rawget(prop, "__set")(self, value);
			return true
		end
	end

	if typeof(value) == "table" and value.__typename == "ObjectProperty" then
		if prop then
			Object.writeProperty(self, name, {
				__value = value.__realvalue
			});
		else
			Object.defineProperty(self, name, Object.defaults({
				__value = value.__realvalue
			}));
		end
	else
		if prop then
			Object.writeProperty(self, name, {
				__value = value
			});
		else
			Object.defineProperty(self, name, Object.defaults({
				__value = value
			}));
		end
	end


	return true;
end



--- Returns pairs value for a property because roblox sucks
-- @param property An ObjectProperty that you want to get the pairs of
function Object.pairs( property : ObjectProperty._ObjectProperty ) : any
	return rawget(property, "__enumerable") and pairs(property.__realvalue);
end



--- Deletes a property
-- @param self An Object instance
-- @param name Name of the property you want to delete
function Object.delete( self : _Object, name : any ) : ObjectProperty._ObjectProperty
	local prop = self[name];
	self[name] = nil;
	return prop;
end



--- Returns ipairs value for a property because roblox sucks
-- @param property An ObjectProperty that you want to get the pairs of
function Object.ipairs( property : ObjectProperty._ObjectProperty ) : any
	return rawget(property, "__enumerable") and ipairs(property.__realvalue);
end



--- Alternative pairs for loop; loops through an Object similar to Array.forEach()
--- @param self An Object instance
--- @param callback Callback function with the arguments k (key) and v (value)
function Object.iterFor( self : _Object, callback : (k : any?, v : any?) -> any? )
	for k, v in self:__pairs() do
		if not rawget(v, "__enumerable") then
			continue
		end
		callback(k, v);
	end 
end



--- Enumerates an Object's properties turning it from keyed to indexed
--- @param self An Object instance
function Object.enumerate( self : _Object ): { [number] : any }
	local i = 0;
	local t = {};
	for _, v in self:__pairs() do
		i += 1;
		if not rawget(v, "__enumerable") then
			continue
		end
		t[i] = v;
	end

	return Object.new(t);
end



--- Alternative ipairs for loop; loops through an Object similar to Array.forEach()
--- @param self An Object instance
--- @param callback Callback function with the arguments i (index) and v (value)
function Object.enumFor( self : _Object, callback : (i : number, v : any?) -> any? )
	for i, v in Object.enumerate(self) do
		callback(i, v);
	end 
end



--- Used to check if a metamethod has a valid "self" value
--- @param self An Object instance
--- @param strict If it should throw an error or just warn
function Object.hasIdentity(self : _Object, strict : boolean?) : boolean
	local strict = strict or config.strict.Value;

	if typeof(self) ~= "table" or not rawget(self, "__typename") then

		if strict then
			JSLikeError.throw("Method.NoSelf");
		else
			JSLikeError.warn("Method.NoSelf");
		end

		return false;
	end

	return true;
end



--- Gets the length of a table
---- @param tbl Table you want to get the length of
function Object.len( tbl: { [any] : any } ) : number
	local i = 0;
	for _, v in tbl do 
		if rawget(v, "__typename") == "ObjectProperty" and not rawget(v, "__enumerable") then continue end
		i += 1; 
	end
	return i;
end



--- Turns a table into a string but funky
--- @param tbl Table to stringify
--- @param wrapper Wrapping strings that go around the entire thing (eg: {"{","}"})
--- @param keyed Decides if it has keys and values or just values
--- @param depth How deep it is changes how it's indented
function Object.stringify(tbl : { [any] : any }, wrapper : { [number] : string }?, keyed : boolean?, depth : number? ) : string
	local wrapper = wrapper or { "{", "}" };
	local length = Object.len(tbl);

	-- if the length of the table is 0 then it just returns {} or whatever the wrapper is
	if length == 0 then
		return wrapper[1]..wrapper[2];
	end

	if typeof(keyed) ~= "boolean" then
		keyed = true;
	end

	local depth = depth or 1

	-- the entries use the normal indent
	-- the wrappers use last indent so they don't show up on the same line as entries
	local indent = pad("", "\t", depth);
	local lastindent = pad("", "\t", depth-1);

	local result = wrapper[1].."\n"

	for key, value in tbl do
		local keyStr = tostring(key)
		local valueStr

		-- if the value has "__" it's marked as a debug-only property and isn't displayed
		-- if the value is an ObjectProperty and is not enumerable then it also isn't displayed
		if string.match(keyStr, "__") or value == tbl or (typeof(value) == "table" and rawget(value, "__typename") and not rawget(value, "__enumerable")) then
			continue;
		end

		-- if a cycle is detected
		if value == tbl then
			valueStr = "*** cycle table reference detected ***";

			-- if it's a table and it has no __tostring method then run another Object.stringify on it one depth down
		elseif typeof(value) == "table" and not value.__tostring then
			valueStr = Object.stringify(value, {"{","}"}, depth + 1)

		else
			-- if it has a __tostring then use that next depth down
			if typeof(value) == "table" and value.__tostring then
				valueStr = value:__tostring(depth + 1)

				-- if it doesn't have an __tostring or isn't a table just tostring it
			else
				valueStr = tostring(value)
			end

			-- if it has a typename then keep getting realvalue until you stop getting ObjectProperty instances so that you can typecheck the actual value
			if typeof(value) == "table" and rawget(value, "__typename") == "ObjectProperty" then
				repeat value = value.__realvalue until typeof(value) ~= "table" or rawget(value, "__typename") ~= "ObjectProperty"
			end

			-- if the result of the last statement is a type then add the typename to it
			if typeof(value) == "table" and rawget(value, "__typename") then
				valueStr = rawget(value, "__typename").." "..valueStr
			end

			-- if it's a string then it adds the '' around it
			if typeof(value) == "string" then  
				valueStr = "'" .. valueStr .. "'";
			end
		end

		-- add the indent
		result = result..indent;

		-- if it's keyed then add the key
		if keyed then
			result = result.."["..keyStr.."] = ";
		end

		-- bring it all together and add an comma at the end as well as a new line
		result = result..valueStr..",\n"
	end

	-- once done gh add another indent and wrap it
	result = result .. lastindent .. wrapper[2];

	return result
end




--- Type checking method for an Object
-- @param self An Object instance, if you use metamethods you should just ignore this
-- @param t Type string to be checked against
function Object.Prototype.__isA(self : _Object, t : string) : boolean
	Object.hasIdentity(self);
	return rawget(self, "__typename") == t;
end



--- Creates a new property inside an Object
-- @param self An Object instance you want to add the property to
-- @param name Name of the property you want to add
-- @param data Table of data to be used to create the property
function Object.defineProperty(self : _Object, name : string, data : { [string]: any }) : ObjectProperty._ObjectProperty?
	local props = rawget(self, "__properties");
	local guh = props[name];

	if guh and not rawget(guh, "__configurable") then
		if rawget(guh, "__strict") then
			JSLikeError.throw("Object.NonConfig", name);
		else
			JSLikeError.warn("Object.NonConfig", name);
		end
		return nil;
	end

	local prop = ObjectProperty.new(self, data);

	local value = rawget(prop, "__value");
	if typeof(value) == "table" and rawget(value, "__typename") == "ObjectProperty" then
		repeat value = value.__realvalue until typeof(value) ~= "table" or rawget(value, "__typename") ~= "ObjectProperty"
	end
	rawset(prop, "__value", value);

	rawget(self, "__properties")[name] = prop;
	return prop;
end



--- Writes to an already existing property without triggering non-configurable errors
-- @param self An Object instance you want to add the property to
-- @param name Name of the property you want to add
-- @param data Table of data to be used to create the property
function Object.writeProperty(self : _Object, name : string, data : { [string]: any }) : ObjectProperty._ObjectProperty?
	local props = rawget(self, "__properties");
	local guh = props[name];

	if guh then

		if not rawget(guh, "__writable") then
			if rawget(guh, "__strict") then
				JSLikeError.throw("Object.ReadOnly", name);
			else
				JSLikeError.warn("Object.ReadOnly", name);
			end
			return nil;
		end

		local blacklist = {
			"__parent",
			"__strict",
			"__writable",
			"__enumerable",
			"__configurable",
			"__extensible",
			"__clonable"
		};

		for k, v in data do
			if blacklist[k] then
				if rawget(guh, "__strict") then
					JSLikeError.throw("Object.DisWrite", name, k);
				else
					JSLikeError.warn("Object.DisWrite", name, k);
				end
				continue
			else
				if not strstarts(k, "__") then k = "__"..k; end
				guh[k] = v;
			end
		end
	else
		if config.strict.Value then
			JSLikeError.throw("Object.MisWrite", name);
		else
			JSLikeError.warn("Object.MisWrite", name);
		end
		return nil;
	end


	local value = rawget(guh, "__value");
	if typeof(value) == "table" and rawget(value, "__typename") == "ObjectProperty" then
		repeat value = value.__realvalue until typeof(value) ~= "table" or rawget(value, "__typename") ~= "ObjectProperty"
	end
	rawset(guh, "__value", value);

	rawget(self, "__properties")[name] = guh;
	return guh;
end



--- Creates new properties inside an Object
-- @param self An Object instance you want to add the properties to
-- @param properties Table of properties to be used to create properties: { [name] = { [descriptor] = [any] } }
function Object.defineProperties(self : _Object, properties : { [string] : { [string] : any } }) : nil
	for name, data in pairs(properties) do
		Object.defineProperty(self, name, data);
	end

	return
end



--- Writes to already existing properties without triggering non-configurable errors
-- @param self An Object instance you want to add the properties to
-- @param properties Table of properties to be used to set properties: { [name] = { [descriptor] = [any] } }
function Object.writeProperties(self : _Object, properties : { [string] : { [string] : any } }) : nil
	for name, data in pairs(properties) do
		Object.writeProperty(self, name, data);
	end

	return
end



--- Gets a shallow property descriptor from an Object
-- @param self Object instance to get descriptors from
-- @param name Name of the property you want to get
function Object.getOwnPropertyDescriptor(self : _Object, name : string) : { [string] : any }
	return clonetbl(rawget(self, "__properties")[name]);
end



--- Gets all shallow property descriptors from an Object
-- @param self Object instance to get descriptors from
function Object.getOwnPropertyDescriptors(self : _Object) : { [string] : { [string] : any } }
	local desc = {};

	for k in pairs(rawget(self, "__properties")) do
		desc[k] = Object.getOwnPropertyDescriptor(self, k);
	end

	return desc
end



--- Assigns variables from on Object or Table to an Object
-- @param self Object instance to assign variables to
-- @param ... Objects or Tables to assign variables from
function Object.assign(self : _Object, ...) : boolean
	for _, assignee in pairs({...}) do
		if typeof(assignee) == "table" and assignee.__typename == "Object" then
			assignee = rawget(assignee, "__properties");
		end

		for k, v in pairs(assignee) do
			if typeof(v) == "table" and v.__typename == "ObjectProperty" then
				rawget(self, "__properties")[k] = v;
			else
				Object.defineProperty(self, k, Object.defaults({
					__value = v
				}));
			end
		end
	end

	return true
end



--- Assigns variables from on Object or Table to an Object without overwriting existing variables
-- @param self Object instance to assign variables to
-- @param ... Objects or Tables to assign variables from
function Object.assignNoOverwrite(self : _Object, ...) : boolean
	for _, assignee in pairs({...}) do
		if typeof(assignee) == "table" and assignee.__typename == "Object" then
			assignee = rawget(assignee, "__properties");
		end

		for k, v in pairs(assignee) do
			if not rawget(self, "__properties")[k] then
				if typeof(v) == "table" and v.__typename == "ObjectProperty" then
					rawget(self, "__properties")[k] = v;
				else
					Object.defineProperty(self, k, Object.defaults({
						__value = v
					}));
				end
			end
		end
	end

	return true
end



--- Applies extendees
-- @param self An Object instance, if you use metamethods you should just ignore this
-- @param ... Arguments you want to run the extendees with
function Object.super(self : _Object, ...) : _Object
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

	return self;
end



--- Gets entries in the object and puts them in a list
-- @param self An Object instance
function Object.entries(self : _Object, blacklist : { [string] : any }? ) : { [number] : any }
	local blacklist = blacklist or {};
	local entries = {};

	for k, v in pairs(rawget(self, "__properties")) do
		if not blacklist[k] then
			table.insert(entries, {
				k, rawget(v, "__truevalue")()
			});
		end
	end

	return entries;
end



--- Gets keys in the object and puts them into a list
-- @param self An Object instance
function Object.keys(self : _Object, blacklist : { [string]: any }? ) : { [number] : any}
	local blacklist = blacklist or {};
	local entries = {};

	for k, v in pairs(rawget(self, "__properties")) do
		if not blacklist[k] then
			table.insert(entries, k);
		end
	end

	return entries;
end



--- Gets values in the object and puts them into a list
-- @param self An Object instance
function Object.values(self : _Object, blacklist : { [string]: any }? ) : { [number]: any }
	local blacklist = blacklist or {};
	local entries = {};

	for k, v in pairs(rawget(self, "__properties")) do
		if not blacklist[k] then
			table.insert(entries, rawget(v, "__realvalue")());
		end
	end

	return entries;
end



--- Prevents new properties from being added to an object, and prevents existing properties from being removed or modified. Returns the object
-- @param self An Object instance
function Object.freeze(self : _Object): _Object
	table.freeze(rawget(self, "__properties"));
	return self;
end



--- Checks if the object is frozen or not
-- @param self An Object instance
function Object.isFrozen(self : _Object) : boolean
	return table.isfrozen(rawget(self, "__properties"))
end



--- Checks if the object is extensible or not
-- @param self An Object instance
function Object.isExtensible(self : _Object) : boolean
	return rawget(self, "__extensible");
end


--- Clones an object
-- @param self An Object instance
function Object.clone(self : _Object, ...) : any
	if not rawget(self, "__clonable") then
		if config.strict.Value then
			JSLikeError.throw("NonClone");
		else
			JSLikeError.warn("NonClone");
		end
		return;
	end

	for _, prop in pairs(rawget(self, "__properties")) do
		if not rawget(prop, "__clonable") then
			if config.strict.Value then
				JSLikeError.throw("NonClone");
			else
				JSLikeError.warn("NonClone");
			end
		end
		return;
	end

	local props = clonetbl(rawget(self, "__properties"));

	return rawget(self, "__type").new(props, ...);
end



function Object.Prototype.__len(self) return #rawget(self, "__properties"); end


function Object.Prototype.__iter(self)
	Object.hasIdentity(self);
	local props = rawget(self, "__properties");
	return function(_, k)
		local key, value = next(props, k)

		if typeof(value) == "table" and not rawget(value, "__enumerable") then
			repeat key, value = next(props, key) until key == nil or (typeof(value) == "table" and rawget(value, "__enumerable"));
		end

		return key, value
	end, props, nil;

end


function Object.Prototype.__ipairs(self)
	Object.hasIdentity(self);
	local i = 0;
	local props = rawget(self, "__properties");

	return function()
		i += 1;
		if i <= #props then
			return i, props[i]
		end
	end, props, nil
end


function Object.Prototype.__pairs(self) return self:__iter() end



if not config.debug.Value then
	function Object.Prototype.__tostring(self, depth : number?)
		local props = rawget(self, "__properties");
		return typeof(props) == "table" and Object.stringify(props, {"{","}"}, true, depth) or tostring(props); 
	end
end



return Object;
