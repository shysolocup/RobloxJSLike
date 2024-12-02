--!strict


local Object = {
    __name = "Object"
};
Object.Prototype = {
    __type = Object,
    __typename = Object.__name,
    __extendees = {}
};


local ObjectProperty = {
    __name = "ObjectProperty"
};
ObjectProperty.Prototype = {
    __type = ObjectProperty,
    __typename = ObjectProperty.__name,
    __extendees = {},
};


type ObjectMeta = typeof(setmetatable({}, Object.Prototype));
type ObjectPropertyMeta = typeof(setmetatable({}, ObjectProperty.Prototype));


export type _Object = ObjectMeta & {
    __properties: _Descriptors,
    __prototype: {[string]: any},

    -- class data
    __type: any,
    __typename: string,
    __extendees: {[number]: string} | nil,

    -- magic methods
    __index: (_Object, name: any) -> any | nil,
    __newindex: (_Object, name: any, value: any) -> any | nil,

    -- typechecking method
    __isA: (_Object, t: string) -> boolean,
}


export type _ObjectProperty = ObjectPropertyMeta & {

    -- value of the property
    __value: any | nil,

    -- if strict is on then it'll crash instead of just doing nothing when you piss off the 3 below this
    -- it's false by default and not technically from the js version of objects but I added it bc you can technically do it by adding "use strict" to a file
    __strict: false,

    -- writable is for read only objects where you can't set things inside of the value
    -- enumerable is if it can be for looped
    -- configurable is for read only objects where you can't set things inside of the descriptors
    __writable: boolean,
    __enumerable: boolean,
    __configurable: boolean,

    -- get is a function ran when a property that doesn't exist is gotten
    -- in js it runs when you get a property at all even if it exists
    -- the only reason it's different is bc lua is shit
    __get: nil | (_ObjectProperty, name) -> any | nil,
    __set: nil | (_ObjecProperty, name, value) -> any | nil,
    __delete: nil | (_ObjectProperty, name) -> any | nil,

    -- magic methods
    __index: (_ObjectProperty, name: any) -> any | nil,
    __newindex: (_ObjectProperty, name: any, value: any) -> any | nil,
}



function ObjectProperty.Prototype.__index(self: any, name: string): any | nil

    -- if the prototype has it then get property through that
    elseif rawget(ObjectProperty.Prototype, name) then
        return rawget(ObjectProperty.Prototype, name);  

    -- if __get exists then get the property through that
    elseif self.__get then 
        return self.__get(self, name);
    
    -- finally if it exists inside of the value itself
    else
        return self.__value;
    end

end


function ObjectProperty.Prototype.__newindex(self: any, name: string, value: any | nil): any | nil

    -- if a __set value exists set through that
    if self.__set then
        self.__set(self, name, value); -- tbl, property name, new value
    
    -- if a __set doesn't exist then set through the value
    else
        self.__value[name] = value;
    end

end


function Object.Prototype.__index(self: any, name: string): any | nil

    -- if it exists in prototype then it has priority over properties
    if rawget(self, "__prototype")[name] then
        return rawget(self, "__prototype")[name];

    -- if it exists in properties get from there
    elseif rawget(self, "__properties")[name] then
        return rawget(self, "__properties")[name];
    end

end


function Object.Prototype.__newindex(self: any, name: string, value: any): any | nil

    -- if it exists in properties then it should change the property
    if self.__properties[name] then
        return self.__properties[name];

    -- if it doesn't then make a new property for it
    else
        return Object.defineProperty(self, name, {
            value = value
        });
    end

end


function copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end


function strstarts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
 end


function Object.defineProperty(self: any, name: string, data: {[string]: any}): nil
    local datafix = {};

    for k, v in pairs(data) do
        if not strstarts(k, "__") then k = "__"..k; end

        datafix[k] = v;
    end

    data = datafix;

    local base = {
        __value = nil,

        __writable = true,
        __configurable = true,
        __enumerable = true,

        __get = nil,
        __set = nil,
        __delete = nil,
    };

    for k, v in pairs(base) do
        if not data[k] then data[k] = v; end
    end

    local prop = prop :: _ObjectProperty

    self.__properties[k] = prop;
end


function Object.new(data: {[string]: any}): _Object
    local self = {
        __type = Object.Prototype.__type,
        __typename = Object.Prototype.__typename,
        __extendees = Object.Prototype.__extendees,
        __prototype = Object.Prototype,

        __properties = {}
    };

    self.__index = self.__properties;
    
    for k, v in pairs(data) do
        Object.defineProperty(self, k, {
            __value = v
        });
    end

    setmetatable(self, Object.Prototype);

    return self :: _Object;
end