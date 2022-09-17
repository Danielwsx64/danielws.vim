local tmux = require("danielws.tmux_runner.tmux")
local input = require("danielws.utils.input")

local notify = require("danielws.utils.notify")

local Self = { _name = tmux._name, _icon = tmux._icon }

local _config = { display_pane_numbers = true, auto_attach = false }

local _current = { first_attach_already_happened = false }

local function set_config(o)
	_config = {
		display_pane_numbers = o.display_pane_numbers or _config.display_pane_numbers,
		auto_attach = o.auto_attach or _config.auto_attach,
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
	tmux.run_shell(command, panel_number)
end

function Self.prompt_attach_to_pane(pane)
	local pane_number = tonumber(pane)

	if pane_number then
		return tmux.set_pane(pane_number)
	end

	local pane_count = tmux.panes_count()

	if pane_count == 1 then
		notify.warn("No pane to attach", Self)

		return
	end

	if pane_count == 2 then
		return tmux.set_pane(tmux.alt_pane())
	end

	if _config.display_pane_numbers then
		tmux.display_panes()
	end

	local selected_pane = tonumber(input.input("Attach to wich pane? #"))

	if not selected_pane then
		notify.warn("No pane specified. Cancelling.", Self)

		return
	end

	tmux.set_pane(selected_pane)
end

return Self
