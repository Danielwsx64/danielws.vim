local Self = {}

local function trim(str)
	local result, _ = str:gsub("\n", ""):gsub("^%s*", ""):gsub("%s*$", ""):gsub("%s%s+", " ")

	return result
end

local function has_pipe(fn_call)
	if string.find(fn_call, "|>") then
		return true
	end
	return false
end

local function get_first_arg_when_is_collection(args)
	local open_char = string.match(args, "^%s*%%?[%.%w]*([{%[])")

	local closes_regex = {
		["{"] = "^(%s*%%?[%.%w]*{.*}),(.*)",
		["["] = "^(%s*%[.*%]),(.*)",
	}

	local first_arg, rest = string.match(args, closes_regex[open_char])

	if not first_arg then
		return args, ""
	end

	return trim(first_arg), rest and trim(rest) or nil
end

local function get_first_arg_when_is_var(args)
	local first_arg, rest = string.match(args, "^%s*(%a+[_%w%.]*),?(.*)")

	return trim(first_arg), rest and trim(rest) or nil
end

local function get_first_arg_when_is_fn(args)
	local fn_call, rest = string.match(args, "^%s*(%a+[_%w%.]*%(.*%)),?(.*)")

	return trim(fn_call), rest and trim(rest) or nil
end

local function is_first_arg_a_var(args)
	return not (string.find(args, "^%s*[%a]+[_%w%.]*,?") == nil)
end

local function is_first_arg_a_fn(args)
	return not (string.find(args, "^%s*%a+[_%w%.]*%(.*,?") == nil)
end

local function split_assigning_statement(line)
	local var_name, fn = string.match(line, "(.*)%s*=%s*(.*)")

	if fn and not (string.find(fn, "^[%s%w_]*[,>%)]+")) then
		return trim(var_name) .. " = ", fn
	end

	return "", line
end

local function get_args(fn_call)
	local fn_name, args = string.match(fn_call, "^%s*([%w_%.]+)%((.*)%)")

	return fn_name, args
end

local function pipelize(fn_call)
	local fn_name, args = get_args(fn_call)

	if args == "" then
		return string.format("%s()", fn_name)
	end

	if is_first_arg_a_fn(args) then
		local arg_fn_call, tail_args = get_first_arg_when_is_fn(args)

		return string.format("%s |> %s(%s)", pipelize(arg_fn_call), fn_name, tail_args)
	end

	if is_first_arg_a_var(args) then
		local first_arg, tail_args = get_first_arg_when_is_var(args)

		return string.format("%s |> %s(%s)", first_arg, fn_name, tail_args)
	end

	local first_arg, tail_args = get_first_arg_when_is_collection(args)

	return string.format("%s |> %s(%s)", first_arg, fn_name, tail_args)
end

local function add_first_arg(first_arg, fn_call)
	local fn_name, args = get_args(fn_call)

	if args ~= "" then
		return string.format("%s(%s, %s)", fn_name, first_arg, args)
	end

	return string.format("%s(%s)", fn_name, first_arg)
end

local function undo_pipelize(line)
	local first_arg, fn_call = string.match(line, "^(.*)|>(.*)")

	if has_pipe(first_arg) then
		return add_first_arg(undo_pipelize(first_arg), trim(fn_call))
	end

	return add_first_arg(trim(first_arg), fn_call)
end

function Self.into_pipe(line)
	local assign_statement, fn_call = split_assigning_statement(trim(line))

	if has_pipe(fn_call) then
		return assign_statement .. undo_pipelize(fn_call)
	else
		return assign_statement .. pipelize(fn_call)
	end
end

-- Used for test
-- local function test(no_pipe, with_pipe, index)
-- 	local pipe_result = Self.into_pipe(no_pipe)
--
-- 	if pipe_result ~= with_pipe then
-- 		print(string.format("Test PIPELIZE failed %s\n\nExpected:\n%s\n\nGot:\n%s\n\n", index, with_pipe, pipe_result))
-- 		return false
-- 	end
--
-- 	local undo_result = Self.into_pipe(with_pipe)
--
-- 	if undo_result ~= trim(no_pipe) then
-- 		print(
-- 			string.format("Test UNDO_PIPELIZE failed %s\n\nExpected:\n%s\n\nGot:\n%s\n\n", index, no_pipe, undo_result)
-- 		)
-- 		return false
-- 	end
--
-- 	return true
-- end
--
-- local examples = {
-- 	{ "funcao(valor_one, valor_two)", "valor_one |> funcao(valor_two)" },
-- 	{ "variavel = funcao(valor_one, valor_two)", "variavel = valor_one |> funcao(valor_two)" },
-- 	{ "\nvariavel \n= \nfuncao(valor_one, valor_two)", "variavel = valor_one |> funcao(valor_two)" },
-- 	{ "funcao(valor_one)", "valor_one |> funcao()" },
-- 	{ "funcao(outra_funcao(valor), segundo_arg)", "valor |> outra_funcao() |> funcao(segundo_arg)" },
-- 	{
-- 		"valor_final = funcao(outra_funcao(terceira()), segundo_arg)",
-- 		"valor_final = terceira() |> outra_funcao() |> funcao(segundo_arg)",
-- 	},
-- 	{
-- 		"final = funcao(valor, build_qualquer_coisa(%{map: valor}, &build(&1)))",
-- 		"final = valor |> funcao(build_qualquer_coisa(%{map: valor}, &build(&1)))",
-- 	},
-- 	{
-- 		'funcao(%{"daniel" => "valor", outra: outro}, build_qualquer_coisa(&build(&1)))',
-- 		'%{"daniel" => "valor", outra: outro} |> funcao(build_qualquer_coisa(&build(&1)))',
-- 	},
-- 	{
-- 		'funcao(%Elixir.Struct{"daniel" => "valor", outra: outro}, build())',
-- 		'%Elixir.Struct{"daniel" => "valor", outra: outro} |> funcao(build())',
-- 	},
-- 	{
-- 		'funcao(%Elixir.Struct{"daniel" => "valor", outra: [1, 2]}, build())',
-- 		'%Elixir.Struct{"daniel" => "valor", outra: [1, 2]} |> funcao(build())',
-- 	},
-- 	{ "funcao([1, 2], build())", "[1, 2] |> funcao(build())" },
-- 	{ "funcao([1, %{daniel: valor}], build())", "[1, %{daniel: valor}] |> funcao(build())" },
-- 	{
-- 		"funcao({:ok, %{ list: [1, [ 2, 3]] }, map: %{ key: value} }, build())",
-- 		"{:ok, %{ list: [1, [ 2, 3]] }, map: %{ key: value} } |> funcao(build())",
-- 	},
-- 	{ "valor = mais_um(%{map: value}, {:ok, [1, 2]})", "valor = %{map: value} |> mais_um({:ok, [1, 2]})" },
-- 	{
-- 		"company = Organization.get_company(connection.company_id)",
-- 		"company = connection.company_id |> Organization.get_company()",
-- 	},
-- 	{ [[
-- 		um_complexo =
-- 			print(%{
-- 				key: value
-- 			})
-- ]], "um_complexo = %{ key: value } |> print()" },
-- }
--
-- for index, entry in ipairs(examples) do
-- 	assert(test(entry[1], entry[2], index))
-- end
--
-- print("Sucesso !!")

return Self
