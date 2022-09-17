local elixir = require("danielws.elixir")
local search = require("danielws.search")
local exit = require("danielws.exit")
local substitute = require("danielws.substitute")

local danielws = {}

local function with_defaults(options)
	return {
		name = options.name or "John Doe",
	}
end

-- This function is supposed to be called explicitly by users to configure this
-- plugin
function danielws.setup(options)
	-- avoid setting global values outside of this function. Global state
	-- mutations are hard to debug and test, so having them in a single
	-- function/module makes it easier to reason about all possible changes
	danielws.options = with_defaults(options)

	-- do here any startup your plugin needs, like creating commands and
	-- mappings that depend on values passed in options
	vim.api.nvim_create_user_command("DWSBetterSearch", search.better_search, {})
	vim.api.nvim_create_user_command("DWSBetterReplace", substitute.better_replace, {})
	vim.api.nvim_create_user_command("DWSGoToTest", elixir.go_to_test, {})
	vim.api.nvim_create_user_command("DWSElixirPipelize", elixir.pipelize, {})
	vim.api.nvim_create_user_command("DWSQuitAll", exit.quit_all, {})
end

function danielws.is_configured()
	return danielws.options ~= nil
end

-- This is a function that will be used outside this plugin code.
-- Think of it as a public API
function danielws.greet()
	if not danielws.is_configured() then
		return
	end

	-- try to keep all the heavy logic on pure functions/modules that do not
	-- depend on Neovim APIs. This makes them easy to test
	local greeting = elixir.greeting(danielws.options.name)
	print(greeting)
end

-- Another function that belongs to the public API. This one does not depend on
-- user configuration
function danielws.generic_greet()
	print("Hello, unnamed friend!")
end

danielws.options = nil
return danielws
