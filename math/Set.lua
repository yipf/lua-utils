require "utils/functors"

local sort=table.sort

local element2str
element2str=function(element)
	if type(element)=="table" then
		local t={}
		for i,e in ipairs(element) do
			t[i]=element2str(e)
		end
		return "<"..table.concat(t,",")..">"
	else
		return tostring(element)
	end
end

local unique=make_unique(element2str)

local new_set=function(S,elements)
	local ns={}
	if elements then 
		local k,v
		for i,element in ipairs(elements) do
			k,v=unique(element)
			ns[k]=v
		end
	end
	return setmetatable(ns,getmetatable(S))
end

local set2str=function(S)
	local t={}
	local push=table.insert
	for k,e in pairs(S) do push(t,k)	end
	sort(t)
	return "{"..table.concat(t,",").."}"
end

local interact=function(A,B)
	local C={}
	for k,e in pairs(A) do
		if B[k] then C[k]=e end
	end
	return setmetatable(C,getmetatable(A))
end

local exclude=function(A,B)
	local C={}
	for k,e in pairs(A) do
		if not B[k] then C[k]=e end
	end
	return setmetatable(C,getmetatable(A))
end

local exclude2=function(A,B)
	local C={}
	for k,e in pairs(A) do
		if not B[k] then C[k]=e end
	end
	for k,e in pairs(B) do
		if not A[k] then C[k]=e end
	end
	return setmetatable(C,getmetatable(A))
end

local union=function(A,B)
	local C={}
	for k,v in pairs(A) do C[k]=v end
	for k,v in pairs(B) do C[k]=v end
	return setmetatable(C,getmetatable(A))
end

local product=function(A,B)
	local C={}
	local k,e
	for ka,a in pairs(A) do
		for kb,b in pairs(B) do
			k,e=unique({a,b})
			C[k]=e
		end
	end
	return setmetatable(C,getmetatable(A))
end

local include=function(A,B)
	for k,e in pairs(B) do
		if not A[k] then return false end
	end
	return true
end

local eq=function(A,B)
	return include(A,B) and include(B,A)
end

local have=function(A,e)
	local k,v=unique(e)
	return A[k]
end

local mt={
	__call=new_set,
	__tostring=set2str,
	__add=union,
	__sub=exclude,
	__mul=interact,
	__div=exclude2,
	__pow=product,
	__eq=eq,
	include=include,
	have=have,
}
mt.__index=mt

Set=setmetatable({},mt)


