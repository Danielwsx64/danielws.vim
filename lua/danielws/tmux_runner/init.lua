local tmux = require("danielws.tmux_runner.tmux")
local input = require("danielws.utils.input")

local notify = require("danielws.utils.notify")

local Self = { _name = tmux._name, _icon = tmux._icon }

local _config = {
	display_pane_numbers = true,
	auto_attach = false,
	try_reattach_before_run = true,
	auto_split = {
		orientation = "h",
	},
}

-- TODO: preciso mesmo desse controlle?
local _current = { first_attach_already_happened = false }

local function set_config(o)
	_config = {
		display_pane_numbers = o.display_pane_numbers or _config.display_pane_numbers,
		auto_attach = o.auto_attach or _config.auto_attach,
		try_reattach_before_run = o.try_reattach_before_run or _config.try_reattach_before_run,
		auto_split = o.auto_split ~= nil and o.auto_split or _config.auto_split,
	}
end

function Self.setup(opts)
	opts = opts.tmux_runner or {}

	set_config(opts)

	-- Add autocmd
	if vim.env.TMUX and _config.auto_attach then
		local group = vim.api.nvim_create_augroup("DWSTmuxRunner", { clear = true })

		vim.api.nvim_create_autocmd("VimEnter", {
			group = group,
			callback = function()
				if not tmux.is_attached() and not _current.first_attach_already_happened then
					Self.prompt_attach_to_pane()
					_current.first_attach_already_happened = true
				end
			end,
		})
	end

	tmux.initialize()
end

function Self.send_command(command, panel_number)
	if panel_number then
		return tmux.run_shell(command, panel_number)
	end

	if tmux.is_attached() then
		return tmux.run_shell(command)
	end

	local panes_count = tmux.panes_count()

	if panes_count == 1 and _config.auto_split then
		Self.split(_config.auto_split.orientation)

		if tmux.set_pane(tmux.alt_pane()) then
			return tmux.run_shell(command)
		end
	end

	if panes_count >= 2 and _config.try_reattach_before_run then
		if Self.prompt_attach_to_pane() then
			return tmux.run_shell(command)
		end
	end

	notify.err("Run aborted because there is no panel attached", Self)
	return false
end

function Self.prompt_attach_to_pane(target_pane)
	if target_pane and target_pane ~= "" then
		return tmux.set_pane(target_pane)
	end

	local pane_count = tmux.panes_count()

	if pane_count == 1 then
		notify.warn("No pane available to attach", Self)

		return false
	end

	if pane_count == 2 then
		return tmux.set_pane(tmux.alt_pane())
	end

	if _config.display_pane_numbers then
		tmux.display_panes()
	end

	local selected_pane = input.input("Attach to wich pane? #")

	if not selected_pane then
		notify.warn("No pane specified. Cancelling.", Self)

		return false
	end

	return tmux.set_pane(selected_pane)
end

function Self.new_window()
	tmux.run_command("new-window")
end

function Self.next_window()
	tmux.run_command("next-window")
end

function Self.previous_window()
	tmux.run_command("previous-window")
end

function Self.last_window()
	tmux.run_command("last-window")
end

Self.resize_vim_pane = tmux.resize_vim_pane
Self.split = tmux.split

return Self
