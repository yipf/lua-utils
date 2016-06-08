
local match=string.match

local ACTIVE_SECTION,ACTIVE_BLOCK={LEVEL=0},nil
local ENV,BLOCKS={ACTIVE_SECTION},{ACTIVE_BLOCK},false
local push,pop,format=table.insert,table.remove,string.format

local get_top=function(stack) 	return stack[#stack] end

local new_section=function(level,caption,option)
	while #STACK>level do pop(STACK) end
	level=#STACK
	section={LEVEL=level,CAPTION=caption,TYPE="SECTION"}
	push(get_top(ENV),section)
	push(STACK,section)
	return section
end

local new_block=function(tp,caption,option)
	caption=caption or "BLOCK"
	local block={CAPTION=caption,TYPE=tp}
	push(get_top(ENV),block)
	push(BLOCKS,block)	
	BLOCKS[caption]=block
	return block
end

local match=string.match
local str2value=function(str,functions)
	for k,v in functions do
		v=v(match(str,k))
		if v then return v end
	end
end

local struct_funcs={}

local import=function(filepath)
	local file=io.open(filepath)
	assert(file,format("Can't open file %q",filepath))
	local push=table.insert
	for line in file:lines() do
		value=str2value(line,struct_funcs)
		if not value then -- normal line
			push(ACTIVE_BLOCK or ACTIVE_SECTION, line)
		end
	end
	file:close()
end

local obj2str
obj2str=function(obj,tp)
	if type(obj)~="table" then return tostring(obj) end
	tp=tp or obj.TYPE or "BLOCK"
	if tp=="SECTION" and not obj.VALUE then
		local t={}
		for i,v in ipairs(obj) do	t[i]=obj2str(v) end
		obj.VALUE=table.concat(t,"\n")
		tp="SECTION"..obj.LEVEL
	else
		obj.VALUE=obj.VALUE or table.concat(obj,"\n")
	end
	local handle=ENV[tp]
	assert(handle,format([[Invalid type %q]],tp))
	tp=type(handle)
	if tp=="string" then 			return (string.gsub(handle,"@(.-)@",obj))
	elseif tp=="function" then 	return handle(obj) 
	end
	return format([[Invalid type %q]],tp)
end

local p2key={["`"]="QUOTE",["$"]="INLINE_EQ",["*"]="EM"}

local eval_string=function(str)
	local func=loadstring(str)
	assert(func,fmt("failed to run script: %q",str))
	return func and func()
end

local element_func

local process_string=function(str)
	return string.gsub(str,"(%p)%1%s*(.-)%s*%1%1",element_func)
end

element_func=function(key,value)
	value=process_string(value)
	if key=="#" then		return eval_string("return "..value)
	else return obj2str(value,p2key[key])
	end
end

local export=function(doc,filepath)
	local str=obj2str(doc)
	str=process_string(str)
	local file=io.open(filepath,"w")
	assert(file,"Can't write to file %q",filepath)
	file:write(str)
	file:close()
end

--------------------------------------------------------------------------------------------------------------------------------------------------
-- struct functions
--------------------------------------------------------------------------------------------------------------------------------------------------

struct_funcs["^[%*%s]*%*()%s+(.-)%s*$"]=function(level,caption) 
	if 	level then 
		ACTIVE_BLOCK=nil -- kill blocks anyway
		ACTIVE_SECTION=new_section(level,caption) 
		return ACTIVE_SECTION
	end
end
	
struct_funcs["^@BEGIN_(%w+)%s*(.-)%s*$"]=function(tp,caption) 
	if 	tp then 
		ACTIVE_BLOCK=new_block(tp,caption) 
		return ACTIVE_BLOCK
	end
end
	
struct_funcs["^@END_(%w+)"]=function(tp)
	if tp then ACTIVE_BLOCK=nil		end
	return ""
end

local paths={}

local add_path=function(path) push(paths,1,path) end
local get_path=function(name) 
	local path=name
	local file=io.open(path)
	if file then file:close() return name end
	local n=#paths
	for i=n,1,-1 do
		path=format("%s/%s",paths[i],name)
		file=io.open(path)
		if file then file:close() return path end
	end
end

local one_line_funcs={
	["INCLUDE"]=function(value) return import(get_path(value)) end,
	["ADD_PATH"]=function(value) push(paths,value) return "" end,
}

struct_funcs["^@([%w_]+)%s+(.-)%s*$"]=function(key,value)
	if key then 
		local func=one_line_funcs[key]
		if func then return func(value) end
		rawset(ACTIVE_BLOCK or ACTIVE_SECTION,key,value)
		return ""
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------
-- GLOBAL FUNCTIONS called by eval_string
--------------------------------------------------------------------------------------------------------------------------------------------------

local get_block=function(key)
	local block=BLOCKS(key)
	assert(block,format("No block named %q",key))
	return block
end

content=function(key)	return table.concat(get_block(key),"\n") end
ref=function(key) 
	local block=get_block(key)
	return obj2str(block,"REF") 
end
set=function(key,value) 	rawset(ENV,key,value) end

--------------------------------------------------------------------------------------------------------------------------------------------------
-- main processdure
--------------------------------------------------------------------------------------------------------------------------------------------------

add_path "/home/yipf/lua-utils/new-org"

local input_file,output_file=...
import(input_file)
local doc=ENV[1]
output_file=output_file or input_file..(ENV["EXT"] or ".txt")
export(doc,output_file)