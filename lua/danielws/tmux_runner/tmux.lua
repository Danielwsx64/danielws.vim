local strings = require("danielws.utils.strings")
local notify = require("danielws.utils.notify")

local Self = { _name = "tmux_runner", _icon = "" }

local current = {
	pane = nil,
	vim_pane = nil,
	major_orientation = nil,
}

local function send_command(command)
	return io.popen("tmux " .. command):read("a")
end

local function send_keys(keys, pane_number)
	local prefix = "tmux send-keys -t " .. pane_number .. " "

	io.popen(prefix .. keys)
end

local function run_shell_command(command, pane_number)
	send_keys(strings.shell_escape(command) .. " Enter", pane_number)
end

local function info(message)
	return send_command("display-message -p '#{" .. message .. "}'")
end

local function bool_info(message, target)
	local result = send_command("display-message -p -F '#{" .. message .. "}' -t " .. target)

	if tonumber(result) == 1 then
		return true
	else
		return false
	end
end

local function get_panes()
	local panes = {}

	for pane in string.gmatch(send_command("list-panes"), "(%d+):") do
		table.insert(panes, tonumber(pane))
	end

	return panes
end

local function is_valid_pane(pane_number)
	local panes = get_panes()

	for i = 1, #panes do
		if pane_number == panes[i] then
			return true
		end
	end

	return false
end

local function is_pane_available(pane_number)
	return pane_number and pane_number ~= current.vim_pane and is_valid_pane(pane_number)
end

local function current_major_orientation()
	local layout = info("window_layout")

	if string.match(layout, "[[{]") == "{" then
		return "vertical"
	else
		return "horizontal"
	end
end

local function active_pane()
	return tonumber(info("pane_index"))
end

local function is_in_copy_mode(pane_number)
	local session_name = vim.trim(info("session_name"))
	local window_index = vim.trim(info("window_index"))

	local target = session_name .. ":" .. window_index .. "." .. pane_number

	return bool_info("pane_in_mode", target)
end

local function quit_copy_mode(pane_number)
	if is_in_copy_mode(pane_number) then
		send_keys("q", pane_number)
	end
end

function Self.panes_count()
	return tonumber(info("window_panes"))
end

function Self.display_panes()
	send_command("display-panes")
end

function Self.set_pane(pane_number)
	if is_pane_available(pane_number) then
		current.pane = pane_number
		current.major_orientation = current_major_orientation()

		notify.info("Attached to pane #" .. pane_number, Self)
	else
		notify.err("Invalid pane number: " .. pane_number, Self)
	end
end

function Self.alt_pane()
	local panes = get_panes()
	for i = 1, #panes do
		if panes[i] ~= current.vim_pane then
			return panes[i]
		end
	end
end

function Self.run_shell(command, pane_number)
	local pane_to_run = pane_number or current.pane

	if not is_pane_available(pane_to_run) then
		notify.err("Specified panel is not available anymore", Self)
		return
	end

	quit_copy_mode(pane_to_run)
	run_shell_command(command, pane_to_run)
end

function Self.is_attached()
	is_pane_available(current.pane)
end

function Self.initialize()
	current.vim_pane = active_pane()
	current.pane = nil
	current.major_orientation = nil
end

return Self
