local elixir = require("danielws.elixir")

describe("greeting", function()
	it("works!", function()
		assert.combinators.match("Hello Gabo", elixir.greeting("Gabo"))
	end)
end)
