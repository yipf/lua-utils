local inputfile,outputfile=...

assert(type(inputfile)=="string","Input filepath must be a string!")

local fmt_string=function(fmt,...)
	return string.format(fmt,...)
end

local file2str=function(filepath)
	local file=io.open(filepath)
	assert(file,fmt_string("Failed to open file %q",filepath))
	local str=file:read("*a")
	file:close()
	return str
end

local BODY_PATTREN="^%(%s*(%w+)%s*(.-)%s*%)$"
local UNIT_PATTREN="%b()"
local REPLACE_PATTREN="@(.-)@"

local copy_props=function(src,dst)
	dst=dst or {}
	for k,v in pairs(src) do dst[k]=v end
	return dst
end

local get_prop
get_prop=function(ref,key)
	if ref then return ref[key] or get_prop(ref.parent,key) end
end

local eval=function(key,value,obj,parent)
	local tp=type(key)
	if tp=="string" then 
		return (string.gsub(key,REPLACE_PATTREN,value))
	elseif tp=="function" then
		return key(value,obj,parent)
	end
	return key
end

local str2obj

str2obj=function(str,obj)
	local parent=obj.parent
	parent.LEVEL=parent.LEVEL or 0
	obj.LEVEL=obj.LEVEL or parent.LEVEL+1
	-- define gsub func
	local match=string.match
	local func=function(str)
		local key,value=match(str,BODY_PATTREN)
		if key then
			key=get_prop(obj,key)
			return eval(key,str2obj(value,{parent=obj}),obj,parent)
		end
		return key
	end
	-- set general value
	obj.VALUE=string.gsub(str,UNIT_PATTREN,func)
	return obj
end

---------------------------------------------------------------------------------------------------------
--  customization and extension
---------------------------------------------------------------------------------------------------------

local SECTIONS={}

local basic_env={
	["LEFTBRACE"]="(",
	["RIGHTBRACE"]=")",
	["QUOTE"]="``@VALUE@''",
	["BRACE"]="(@VALUE@)",
	["EM"]="**@VALUE@**",
	["SET"]=function(child,obj,parent)
		local key,value=string.match(child.VALUE,"^%s*(%w+)%s*(.-)%s*$")
		if key then 
			obj[key]=value
			return ""
		end
	end,
	["SECTION"]=function(child,obj,parent)
		local pat=get_prop(child,tostring(child.LEVEL))
		return eval(pat,child)
	end,
	["INCLUDE"]=function(child,obj,parent)
		value=str2obj(file2str(child.VALUE),obj)
		return ""
	end,
	["EVAL"]=function(child)
		local str=child.VALUE
		return str
	end,
	["PRINT"]=function(child)
		print(child.VALUE)
		return ""
	end,
	LEVEL=0,
}

---------------------------------------------------------------------------------------------------------
--  process
---------------------------------------------------------------------------------------------------------

local doc=str2obj(file2str(inputfile),{parent=basic_env,LEVEL=0})
local str=eval(doc[tostring(doc.LEVEL)],doc)

---------------------------------------------------------------------------------------------------------
--  output
---------------------------------------------------------------------------------------------------------

outputfile=outputfile or inputfile.."."..doc.EXT
print(fmt_string("Writing to %q",outputfile))
local f=io.open(outputfile,"w")
assert(f,fmt_string("Can't open file %q",outputfile))
f:write(str)
f:close()
print("Done!")


