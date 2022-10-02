local changed_buffers_picker = require("danielws.pickers.changed_buffers")
local notify = require("danielws.utils.notify")

local Self = { _name = "Exit", _icon = "" }

function Self.close_session()
	vim.cmd("DeleteSession")
	vim.cmd("qa!")
end

function Self.quit_all()
	for _, buf_info in ipairs(vim.fn.getbufinfo()) do
		if buf_info.changed ~= 0 then
			if vim.fn.getbufinfo(vim.api.nvim_get_current_buf())[1].changed ~= 0 then
				vim.cmd("tabnew")
			end

			notify.warn("Unsaved opened buffers. Close then first.", Self)
			changed_buffers_picker.changed_buffers()
			return
		end
	end

	vim.cmd("qa")
end

return Self
