local inputfile,outputfile=...

--~ assert(type(inputfile)=="string","Input filepath must be a string!")

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

local BODY_PATTREN="^%%s*(%w+)%s*(.-)%s*%$"
local UNIT_PATTREN="()%b()()"
local REPLACE_PATTREN="@(.-)@"

append_str=function(tree,str)
	str=match(str,"^%s*(%S.-)%s*$")
	if str then table.insert(tree,str) end
end

str2list=function(str,list)
	local s,e,frag=1,string.len(str)
	local push,sub,match=table.insert,string.sub,string.match
	for ss,ee in string.gmatch(str,UNIT_PATTREN) do
		if ss>s then
			frag=match(sub(str,s,ss-1),"^%s*(%S.-)%s*$")
			if frag then push(list,frag) end
		end
		push(list,{TEXT=sub(str,ss+1,ee-2),parent=list})
		s=ee
	end
	if e>=s then
		frag=match(sub(str,s,e),"^%s*(%S.-)%s*$")
		if frag then push(list,frag) end
	end
	return list
end

eval_list=function(list)
	local parent,text=list.parent,list.TEXT
	list.LEVEL=parent.LEVEL+1
	local key,value=string.match(text,BODY_PATTREN)
	
	return list
end

---------------------------------------------------------------------------------------------------------
--  customization and extension
---------------------------------------------------------------------------------------------------------

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


local str=[[
(INCLUDE /home/yipf/lua-utils/S-document/html.ydoc)

aa(SET CAPTION my first title)bb
cc(SECTION (SET CAPTION TEST)
(PARAGRAPH  my paragraph is right )
(SECTION (SET CAPTION 222)
	sadfadsf asdf asdf asdf asdf asd
	asdf asdf asd f
	asdf asdf asdf asdf asdf 
)
)asdfdsfasdf]]



local doc=str2list(str,{parent=basic_env,LEVEL=0})

for i,v in ipairs(doc) do
	print(i,eval_list(v))
end















