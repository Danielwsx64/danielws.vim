local strings = require("danielws.utils.strings")
local notify = require("danielws.utils.notify")

local Self = { _name = "tmux_runner", _icon = "" }

local current = {
	attached_pane = nil,
	vim_pane_id = nil,
}

function Self.run_command(command, target_pane)
	local line = string.format("tmux %s", command)

	if target_pane then
		line = string.format("%s -t%s", line, target_pane)
	end

	return io.popen(line):lines()
end

local function send_keys(keys, target_pane)
	io.popen(string.format("tmux send-keys -t%s %s", target_pane, keys))
end

local function run_shell_command(command, target_pane)
	send_keys("C-c", target_pane)
	send_keys(strings.shell_escape(command) .. " Enter", target_pane)
end

local function get_info(messages, target_pane)
	local full_message = ""

	for index, message in ipairs(messages) do
		if index == 1 then
			full_message = string.format("#{%s}", message)
		else
			full_message = string.format("%s:#{%s}", full_message, message)
		end
	end

	local display_message = string.format("display-message -p -F '%s'", full_message)

	return Self.run_command(display_message, target_pane)()
end

local function bool_info(message, target)
	return tonumber(get_info({ message }, target)) == 1 and true or false
end

local function get_panes()
	local panes = {}

	local list = Self.run_command("list-panes")

	for line in list do
		local number = string.match(line, "(%d+):")

		if number then
			local id = string.match(line, "(%%%d+)")

			table.insert(panes, { id = id, number = number })
		end
	end

	return panes
end

local function is_vim_pane_id(test_id)
	return test_id == current.vim_pane_id
end

local function is_valid_pane(target_pane)
	local ref = type(target_pane) == "table" and target_pane.id or target_pane

	for _, pane_info in ipairs(get_panes()) do
		if pane_info.id == ref or pane_info.number == ref then
			return true, pane_info
		end
	end

	return false, nil
end

local function is_pane_available_for_run(target_pane)
	if target_pane == nil then
		return false, nil
	end

	local available, info = is_valid_pane(target_pane)

	if (not available or not info) or is_vim_pane_id(info.id) then
		return false, nil
	end

	return available, info
end

local function current_major_orientation()
	local layout = get_info({ "window_layout" })

	if string.match(layout, "[[{]") == "{" then
		return "v"
	else
		return "h"
	end
end

local function is_in_copy_mode(pane_number)
	local session_name = vim.trim(get_info({ "session_name" }))
	local window_index = vim.trim(get_info({ "window_index" }))

	local target = session_name .. ":" .. window_index .. "." .. pane_number

	return bool_info("pane_in_mode", target)
end

local function quit_copy_mode(pane_number)
	while is_in_copy_mode(pane_number) do
		send_keys("-X cancel", pane_number)
	end
end

local function set_vim_pane_id(id)
	current.vim_pane_id = id
end

local function set_attached_pane(pane)
	current.attached_pane = pane
end

local function get_vim_pane_id()
	return current.vim_pane_id
end

function Self.panes_count()
	return tonumber(get_info({ "window_panes" }))
end

function Self.split(orientation)
	if orientation == "h" then
		Self.run_command("splitw -h")
	elseif orientation == "v" then
		Self.run_command("splitw -v")
	else
		Self.split(current_major_orientation())
	end

	return true
end

function Self.display_panes()
	Self.run_command("display-panes")
end

function Self.set_pane(pane)
	local available_pane, pane_info = is_pane_available_for_run(pane)

	if available_pane and pane_info ~= nil then
		set_attached_pane(pane_info)

		notify.info(string.format("Attached to pane #%s id: %s", pane_info.number, pane_info.id), Self)
		return true
	else
		notify.err("Pane not available for attach: " .. vim.inspect(pane), Self)
		return false
	end
end

function Self.alt_pane()
	for _, pane_info in ipairs(get_panes()) do
		if not is_vim_pane_id(pane_info.id) then
			return pane_info
		end
	end
end

function Self.run_shell(command, pane_number)
	local run_into_pane = pane_number or Self.get_attached_pane()
	local available_pane, pane_info = is_pane_available_for_run(run_into_pane)

	if not available_pane or pane_info == nil then
		notify.err("Specified panel is not available anymore: " .. vim.inspect(run_into_pane), Self)
		return false
	end

	quit_copy_mode(pane_info.id)
	run_shell_command(command, pane_info.id)
	return true
end

function Self.get_attached_pane()
	return current.attached_pane
end

function Self.is_attached()
	local pane_available = is_pane_available_for_run(Self.get_attached_pane())

	return pane_available
end

function Self.resize_vim_pane(value)
	if value == "z" or value == "Z" then
		Self.run_command("resize-pane -Z", get_vim_pane_id())

		return true
	end

	value = tonumber(value)

	if value then
		Self.run_command(string.format("resize-pane -y%s%% -x%s%%", value, value), get_vim_pane_id())

		return true
	end

	return false
end

function Self.initialize()
	set_attached_pane(nil)
	set_vim_pane_id(get_info({ "pane_id" }))
end

return Self
