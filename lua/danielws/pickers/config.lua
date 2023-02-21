local themes = require("telescope.themes")

Self = {}

function Self.get_opts(opts)
	return themes.get_ivy(opts or {})
end

return Self
