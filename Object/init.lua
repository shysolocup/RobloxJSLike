--!strict


local Object = {};
Object.Prototype = {
    __type = "Object",
    __extendees = {},
    __events = {}
};


type meta = typeof(setmetatable({}, Object.Prototype));


export type _Object = meta & {
    __value: any | nil,

    -- writeable is for read only objects but it's not safe idk why it even exists bc you can just set it to false
    -- enumerable is ignored in for loops
    -- configurable is for safer read only objects
    __writeable: boolean,
    __enumerable: boolean,
    __configurable: boolean,

    -- get is a function ran when a property that doesn't exist is gotten
    -- in js it runs when you get a property at all even if it exists
    -- the only reason it's different is bc lua is shit
    __get: (_Object, name) -> any | nil
    __set: (_Object, name, value) -> any | nil
    __delete: (_Object, name) -> any | nil

    __prototype: {[string]: any}

    -- class data
    __type: string,
    __extendees: {[number]: string},

    -- magic methods
    __index: (_Object, name: any) -> any | nil
    __newindex: (_Object, name: any, value: any) -> any | nil

    -- typechecking method
    __isA: (_Object, t: string) -> boolean,
}



function Object.Prototype.__index(self: any, name: any | nil): any | nil

    -- if the prototype has it then get property through that
    elseif rawget(Object.Prototype, name) then
        return rawget(Object.Prototype, name);  

    -- if __get exists then get the property through that
    elseif rawget(self, "__get") then 
        return rawget(self, "__get")(self, name);
    
    -- finally if it exists inside of the value itself
    else
        return rwaget(self, "__value")[name];
    end
end


function Object.Prototype.__newindex(self: any, name: any | nil, value: any | nil): any | nil
    -- if a __set value exists set through that
    if rawget(self, "__set") then
        rawget(self, "__set")(self, name, value);
    
    -- if a __set doesn't exist then set through the value
    else
        rawget(self, "__value")[name] = value;
    end
end


function copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end


function Object.new(data: {[string]: any}): _Object
    local base = {
        __type = Object.Prototype.__type,
        __extendees = Object.Prototype.__extendees,
        __prototype = Object.Prototype,

        __writeable = true,
        __enumerable = true,
        __configurable = true,
    };

    local self = copy(base);
    self.__value = {};

    for k, v in pairs(data) do
        self.__value[k] = 
    end

    setmetatable(self, Object.Prototype);

    return self :: _Object;
end