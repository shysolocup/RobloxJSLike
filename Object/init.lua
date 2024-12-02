--!strict


local Object = {
    __name = "Object"
};
Object.Prototype = {
    __type = Object,
    __typename = Object.__name,
    __extendees = {}
};


local Descriptors = {
    __name = "Descriptors"
};
Descriptors.Prototype = {
    __type = Descriptors,
    __typename = Descriptors.__name,
    __extendees = {}
};


type ObjectMeta = typeof(setmetatable({}, Object.Prototype));
type DescriptorMeta = typeof(setmetatable({}, Descriptors.Prototype));


export type _Descriptors = DescriptorMeta & {

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
    __get: (_Object, name) -> any | nil,
    __set: (_Object, name, value) -> any | nil,
    __delete: (_Object, name) -> any | nil,

    -- class data
    __type: any,
    __typename: string,
    __extendees: {[number]: string} | nil,

    -- magic methods
    __index: (_Object, name: any) -> any | nil,
    __newindex: (_Object, name: any, value: any) -> any | nil,
}


export type _Object = ObjectMeta & {
    __descriptors: _Descriptors,
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



function Object.Prototype.__index(self: any, name: any | nil): any | nil

    local descriptors = rawget(self, "__descriptors");

    -- if the prototype has it then get property through that
    elseif rawget(Object.Prototype, name) then
        return rawget(Object.Prototype, name);  

    -- if __get exists then get the property through that
    elseif descriptors.__get then 
        return descriptors.__get(self, name);
    
    -- finally if it exists inside of the value itself
    else
        return descriptors.__value;
    end
end


function Object.Prototype.__newindex(self: any, name: any | nil, value: any | nil): any | nil
    local descriptors = rawget(self, "__descriptors");

    -- handling for writable
    if descriptors.__writable then
        if descriptors.__strict then error("Type error: Property "..name.." is read-only") end
        return
    end


    -- if a __set value exists set through that
    if descriptors.__set then
        descriptors.__set(self, name, value);
    
    -- if a __set doesn't exist then set through the value
    else
        descriptors.__value[name] = value;
    end
end


function copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end


function Object.defineProperty(self: any, name: string, data: {[string]: any}): nil
    
end


function Object.new(data: {[string]: any}): _Object
    local self = {};
    
    for k, v in pairs(data) do
        local desc: _Descriptors = {
            __value = v,

            __writable = { true },
            __configurable = { true },
            __enumerable = { true },

            __get = nil,
            __set = nil,
            __delete = nil,
        };

        self[k] = desc;
    end

    setmetatable(self, Object.Prototype);

    return self :: _Object;
end