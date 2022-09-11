local Self = {}

local function trim(str)
	local result, _ = str:gsub("\n", ""):gsub("^%s*", ""):gsub("%s*$", ""):gsub("%s%s+", " ")

	return result
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

local function pipelize(fn_call)
	local fn_name, args = string.match(fn_call, "^([%w_%.]+)%((.*)%)")

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

function Self.into_pipe(line)
	local assign_statement, fn_call = split_assigning_statement(trim(line))

	return assign_statement .. pipelize(fn_call)
end

-- Used for test
-- local function test(value, expected)
-- 	if value ~= expected then
-- 		print(string.format("Test failed\n\nExpected:\n%s\n\nGot:\n%s\n\n", expected, value))
-- 		return false
-- 	end
--
-- 	return true
-- end
--
-- local primeira = "funcao(valor_one, valor_two)"
-- local segunda = "variavel = funcao(valor_one, valor_two)"
-- local terceira = "\nvariavel \n= \nfuncao(valor_one, valor_two)"
-- local quarta = "funcao(valor_one)"
-- local quinta = "funcao(outra_funcao(valor), segundo_arg)"
-- local sexta = "valor_final = funcao(outra_funcao(terceira()), segundo_arg)"
-- local setima = "final = funcao(valor, build_qualquer_coisa(%{map: valor}, &build(&1)))"
-- local oitava = 'funcao(%{"daniel" => "valor", outra: outro}, build_qualquer_coisa(&build(&1)))'
-- local nona = 'funcao(%Elixir.Struct{"daniel" => "valor", outra: outro}, build())'
-- local deca = 'funcao(%Elixir.Struct{"daniel" => "valor", outra: [1, 2]}, build())'
-- local onza = "funcao([1, 2], build())"
-- local doza = "funcao([1, %{daniel: valor}], build())"
-- local treza = "funcao({:ok,  %{ list: [1, [ 2, 3]] }, map: %{ key: value} }, build())"
-- local quator = [[
--     um_complexo =
--       print(%{
--         key: value
--       })
-- ]]
-- local quinze = "valor = mais_um(%{map: value}, {:ok, [1, 2]})"
-- local dezeis = "company = Organization.get_company(connection.company_id)"
--
-- assert(test(Self.into_pipe(primeira), "valor_one |> funcao(valor_two)"))
-- assert(test(Self.into_pipe(segunda), "variavel = valor_one |> funcao(valor_two)"))
-- assert(test(Self.into_pipe(terceira), "variavel = valor_one |> funcao(valor_two)"))
-- assert(test(Self.into_pipe(quarta), "valor_one |> funcao()"))
-- assert(test(Self.into_pipe(quinta), "valor |> outra_funcao() |> funcao(segundo_arg)"))
-- assert(test(Self.into_pipe(sexta), "valor_final = terceira() |> outra_funcao() |> funcao(segundo_arg)"))
-- assert(test(Self.into_pipe(setima), "final = valor |> funcao(build_qualquer_coisa(%{map: valor}, &build(&1)))"))
-- assert(test(Self.into_pipe(oitava), '%{"daniel" => "valor", outra: outro} |> funcao(build_qualquer_coisa(&build(&1)))'))
-- assert(test(Self.into_pipe(nona), '%Elixir.Struct{"daniel" => "valor", outra: outro} |> funcao(build())'))
-- assert(test(Self.into_pipe(deca), '%Elixir.Struct{"daniel" => "valor", outra: [1, 2]} |> funcao(build())'))
-- assert(test(Self.into_pipe(onza), "[1, 2] |> funcao(build())"))
-- assert(test(Self.into_pipe(doza), "[1, %{daniel: valor}] |> funcao(build())"))
-- assert(test(Self.into_pipe(treza), "{:ok, %{ list: [1, [ 2, 3]] }, map: %{ key: value} } |> funcao(build())"))
-- assert(test(Self.into_pipe(quator), "um_complexo = %{ key: value } |> print()"))
-- assert(test(Self.into_pipe(quinze), "valor = %{map: value} |> mais_um({:ok, [1, 2]})"))
-- assert(test(Self.into_pipe(dezeis), "company = connection.company_id |> Organization.get_company()"))
--
-- print("Sucesso !!")

return Self
