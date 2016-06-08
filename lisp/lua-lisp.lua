
local format=string.format

local make_var_func=function(prefix)
	prefix =prefix or  "variable_"
	local format=string.format
	local container,id={},0
	return function(str)
		if not str then 
			str=table.concat(container,"",1,id) 
			id=0
			return str
		end
		id=id+1
		local name=prefix..id
		container[id]=format("local %s=%s\n",name,str)
		return name
	end
end

list2table=function(str)
	local gsub=string.gsub
	local func=make_var_func("VAR_")
	str=string.match(str,"^%s*(.-)%s*$")
	str=gsub(str,"\".-[^\\]\"",func) -- replace quoted string with symbols
	str=gsub(str,"%(%s+","%(") -- process start of list
	str=gsub(str,"%s+%)","%)") -- process end of list
	str=gsub(str,"%s+",",") -- process spaces
	str=gsub(str,"%(","{") -- `(` ==>`{`
	str=gsub(str,"%)","}") -- ')' ==> `}`
	str=format("%s\nreturn %s",func(),str)
	print(str)
	return loadstring(str)()
end

list2table" (+ 2 3 (/ 3  5) \"asdfasf\")"