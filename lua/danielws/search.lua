local vim_utils = require("danielws.utils.vim")

local Self = {}

function Self.better_search()
	if vim_utils.is_visual_mode() then
		vim.fn.setreg("/", vim_utils.get_visual_selection())
	else
		vim.fn.setreg("/", string.format("\\<%s\\>", vim.fn.expand("<cword>")))
	end

	vim.cmd("set hls")
end

return Self
