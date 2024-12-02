--!strict


local Object = {
    __name = "Object"
};
Object.Prototype = {
    __type = Object,
    __typename = Object.__name,
    __extendees = {}
};


type meta = typeof(setmetatable({}, Object.Prototype));


export type _Descriptors = {
    __value: any | nil,

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
}


export type _Object = meta & {
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


function Object.new(data: any): _Object
    for 
    
    local desc: _Descriptors = {
        __value = 
    }
end