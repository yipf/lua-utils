
local push,pop,fmt=table.insert,table.remove,string.format

local TOP={LEVEL=0}
local ENV={TOP} -- ENV[string] is string or functions, while ENV[#id] is document blocks
local BLOCKS={TOP}
local FUNCTIONS={}
local COUNTERS={}

local execute_cmd=function(cmd)
	local key,value=string.match(cmd,"^([%w_]+)%s*(.-)$")
	assert(key,fmt("Invalid command %q",cmd))
	local func=FUNCTIONS[key]
	if func then 
		return func(value) 
	else
		TOP[key]=value
	end
end

local import=function(filepath)
	local file=io.open(filepath)
	assert(file,fmt("Can't open file %q",filepath))
	local t,i,str={},0
	local match,concat,push=string.match,table.concat,table.insert
	for line in file:lines() do
		str=match(line,"^@%s*(.-)%s*$") -- test if current line is a evalable line
		if str then 
			str=execute_cmd(str)
			if str then push(TOP,str) end
		else
			push(TOP,line)
		end
	end
	file:close()
end

local eval_obj=function(key,value)
	local func=ENV[key]
	local tp=type(func)
	if tp=="string" then 
		return (string.gsub(func,"@(.-)@",value))
	elseif tp=="function" then
		return func(value)
	end
end

local block2str

local block2value=function(block)
	local t={}
	if obj.TYPE=="SECTION" then
		for i,v in ipairs(obj) do			t[i]=block2str(v)		end
	else
		for i,v in ipairs(obj) do			t[i]=v						end
	end
	return table.concat(t,"\n")
end

block2str=function(block)
	if type(obj)~="table" then return tostring(block) end
	obj.VALUE=obj.VALUE or block2value(block)
	local tp=obj.TYPE
	return eval_obj(tp=="SECTION" and tp..(obj.LEVEL) or tp or "default",obj)
end

local export=function(filepath,doc)
	doc=doc or ENV[1]
	local str=block2str(doc)
	local file=filepath and io.open(filepath)
	assert(file,fmt("Can't store to file %q with content:\n")..str)
	file:write(str)
	file:close()
	return obj
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTIONS called at first pass - structural pass
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local update_top=function(tp,caption)
	local level=#ENV
	if TOP.TYPE~="SECTION" then TOP=ENV[level] 	end -- set TOP to an uplevel section
	local block={CAPTION=caption,LEVEL=level,TYPE=tp,PARENT=TOP} -- generate a new block 
	BLOCKS[caption]=block; 	push(BLOCKS,block);	-- register block
	push(TOP,block); 	push(ENV,block);		TOP=block; -- update TOP
end

local eval_string=function(str)
	local func=loadstring(str)
	assert(func,fmt("failed to run script: %q",str))
	return func and func()
end

FUNCTIONS["SECTION"]=function(caption)  update_top("SECTION",caption) end
FUNCTIONS["FIGURE"]=function(caption)  update_top("FIGURE",caption) end
FUNCTIONS["EQUATION"]=function(caption)  update_top("EQUATION",caption) end
FUNCTIONS["TABLE"]=function(caption)  update_top("TABLE",caption) end
FUNCTIONS["BLOCK"]=function(caption)  update_top("BLOCK",caption) end

FUNCTIONS["END"]=function(caption)
	TOP=pop(ENV)
	if caption and match(caption,"%S") then
		while TOP.caption~=caption do TOP=pop(ENV) end
	end
	TOP=ENV[#ENV]
end

FUNCTIONS["INCLUDE"]=import

FUNCTIONS["SAVE_AS"]=function(key)
	local block=BLOCKS[#BLOCKS]
	key= key=="" and block.caption or  key
	ENV[key]=block2value(block)
end

FUNCTIONS["EVAL_AND_SAVE_AS"]=function(key)
	local block=BLOCKS[#BLOCKS]
	key= key=="" and block.caption or  key
	ENV[key]=eval_string(block2value(block))
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTIONS called at second pass ------- text processing pass
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------- 
-- main
---------------------------------------------------------------------------------------

local input_file,output_file=...
import(input_file)
local doc=ENV[1]
output_file=output_file or input_file..(doc.EXT or ".txt")
export(output_file)

