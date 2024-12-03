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
	__extendees = { Object }
};


type _ArrayMeta = typeof(setmetatable({}, Array.Prototype));


export type _Array = _ArrayMeta & {
	__properties: any,
	__prototype: {[string]: any},

	-- class data
	__type: any,
	__typename: string,
	__extendees: {[number]: string} | nil,

	-- magic methods
	__index: (_Array, name: string) -> any | nil,
	__newindex: (_Array, name: string, value: any) -> boolean,
}



return Array;