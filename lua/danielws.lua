local elixir = require("danielws.elixir")
local search = require("danielws.search")
local exit = require("danielws.exit")
local tmux_runner = require("danielws.tmux_runner")
local substitute = require("danielws.substitute")

local danielws = {}

danielws.options = nil

local function with_defaults(options)
	return {
		tmux_runner = options.tmux_runner or {},
	}
end

-- This function is supposed to be called explicitly by users to configure this
-- plugin
-- tmux
function danielws.setup(options)
	-- avoid setting global values outside of this function. Global state
	-- mutations are hard to debug and test, so having them in a single
	-- function/module makes it easier to reason about all possible changes
	danielws.options = with_defaults(options)

	tmux_runner.setup(options)

	-- do here any startup your plugin needs, like creating commands and
	-- mappings that depend on values passed in options
	vim.api.nvim_create_user_command("DWSBetterSearch", search.better_search, {})
	vim.api.nvim_create_user_command("DWSBetterReplace", substitute.better_replace, {})
	vim.api.nvim_create_user_command("DWSGoToTest", elixir.go_to_test, {})
	vim.api.nvim_create_user_command("DWSElixirPipelize", elixir.pipelize, {})
	vim.api.nvim_create_user_command("DWSQuitAll", exit.quit_all, {})

	-- TmuxRunner commands
	vim.api.nvim_create_user_command("VtrAttachToPane", function(opts)
		tmux_runner.prompt_attach_to_pane(opts.args)
	end, { nargs = "*" })

	vim.api.nvim_create_user_command("VtrSendCommand", function(opts)
		tmux_runner.send_command(opts.args)
	end, { nargs = "*" })

	-- TODO: I need this for using vim-test plugin
	vim.cmd([[
		function! VtrSendCommand(command, ...)
			 call v:lua.require("danielws.tmux_runner").send_command(a:command)
		endfunction
	]])
end

return danielws
