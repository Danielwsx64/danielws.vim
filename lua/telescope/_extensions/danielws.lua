return require("telescope").register_extension({
	exports = {
		co_authors = require("danielws.pickers.co_authors").co_authors,
	},
})
