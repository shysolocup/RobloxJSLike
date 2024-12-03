local Object = require(game.ReplicatedStorage.JSLike.Object);
local err = require(game.ReplicatedStorage.JSLike.Config.Errors);
local obj = Object.new();

local a = "b";

Object.defineProperty(obj, "test", {
	get = function(self)
		return a;
	end,
})


print(obj.test)

obj.test = "c";

print(obj.test);
