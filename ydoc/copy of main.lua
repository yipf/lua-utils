
local ROOT={LEVEL=0}
local ENV,BLOCKS={ROOT},{["ROOT"]=ROOT}
local push,pop,format,match=table.insert,table.remove,string.format,string.match

local append=push
--------------------------------------------------------------------------------------------------------------------------------------------------
-- BASIC FUNCTIONS
--------------------------------------------------------------------------------------------------------------------------------------------------

local tostring,next=tostring,next

local str2args=function(str)
	local args,i,key={[0]=str,["0"]=str},0
	for e in string.gmatch(str,"%s*(.-)%s+|") do
		i=i+1;			args[i]=e;		args[tostring(i)]=e;		
	end
	return args
end

local get_top=function(stack)
	local last=#stack
	return stack[last],last 
end

local register_block=function(block,option)
	block.TYPE=block.TYPE or "P"
	if block.CAPTION then rawset(BLOCKS,block.CAPTION,block) end
	if block.LABEL then rawset(BLOCKS,block.LABEL,block) end
	if option=="PUSH" then push(BLOCKS,block) end
	return block
end

local push_section=function(section)
	append(ENV[#ENV],section)
	push(ENV,section)
	return section
end

local pop_sections=function(level,stack) -- pop section stack until #stack==level
	level,stack=level and level>0 and level or 1, stack or ENV
	while #stack>level do  register_block(pop(stack))	end
	return get_top(stack)
end

--------------------------------------------------------------------------------------------------------------------------------------------------
-- IMPORT
--------------------------------------------------------------------------------------------------------------------------------------------------

local process_block=function(block,parent)
	if block[1] then -- if block has normal text
		append(parent,register_block(block,"PUSH"))
	else -- otherwise, the block is treated as only a property set, copy properties and clear them to reuse block
		for k,v in pairs(block) do	parent[k]=v end
	end
	return {}
end

local process_line=function(line,block,section,handles)
	local level,key,value
	-- for section lines
	level,value=match(line,"^%*+()%s+(.-)%s*$") 	-- test if current line is starting a section
	if level then -- if true
		if next(block) then block=process_block(block,section) end -- if block is not empty, apply block
		section,level=pop_sections(level-1) -- pop ENV until #ENV=level-1
		if value~="" then section=push_section({TYPE="SECTION",LEVEL=level,CAPTION=value}) end
		return block,section
	end
	-- for special lines
	key,value=match(line,"^#%+%s*([%w_]+)%s+(.-)%s*$") 	-- test if current line is a special line
	if key then -- if true
		level=handles[key]
		if level then level(value) 
		else	block[key]=value end
		return block,section
	end
	-- for table lines
	key=match(line,"^|%s*(.-)%s*$") 	-- test if current line is a table row
	if key then -- if true
		if not block.TYPE then block.TYPE="TABLE" end
		push(block,str2args(key))
		return block,section
	end
	-- for list lines
	-- for normal lines
	push(block,line)
	return block,section
end

local import=function(filepath)
	local file=io.open(filepath)
	assert(file,format("Can't open file %q",filepath))
	local section,level=get_top(ENV)
	local block={}
	for line in file:lines() do
		if match(line,"%S") then -- if line is not empty
			block,section=process_line(line,block,section,_G)
		else -- if line is an empty line
			block=process_block(block,section)
		end
	end
	if next(block) then block=process_block(block,section) end  -- if block is not empty, apply block
	pop_sections(level)
	file:close()
end

--------------------------------------------------------------------------------------------------------------------------------------------------
-- EXPORT
--------------------------------------------------------------------------------------------------------------------------------------------------

local eval_string=function(str)
	local func=loadstring(str)
	assert(func,fmt("failed to run script: %q\n",str))
	return func()
end

local eval_obj=function(obj,key,handles)
	handles=handles or ENV
	local handle=handles[key]
	local tp=type(handle)
	if tp=="string" then 			return (string.gsub(handle,"@(.-)@",obj))
	elseif tp=="function" then 	return handle(obj) 
	end
end

local process_url=function(url,handles)
	local key,value=match(url,"^%s*(%w+):%s*(.-)%s*$")
	return key and eval_obj(str2array(value),key,handles)
end

local obj2str
obj2str=function(obj,tp)
	if type(obj)~="table" then return tostring(obj) end -- for raw text
	tp=tp or obj.TYPE or "P"
	if not obj.VALUE then -- for objects
		local t={}
		for i,v in ipairs(obj) do	t[i]=obj2str(v) end
		obj.VALUE=table.concat(t,"\n")
		if tp=="SECTION" then tp="SECTION"..obj.LEVEL end
	end
	-- generate string according to tp
	local handle=ENV[tp]
	assert(handle,format([[Invalid type %q]],tp))
	tp=type(handle)
	if tp=="string" then 			return (string.gsub(handle,"@(.-)@",obj))
	elseif tp=="function" then 	return handle(obj) 
	end
	return format([[Invalid type handle: [%s] ]],tostring(tp))
end

local process_url=function(url)
	local key,value=match(url,"^%s*(%w+)%:%s*(.-)%s*$")
	
end

local element_func,process_string
local p2key={["`"]="QUOTE",["$"]="INLINE_EQ",["*"]="EM"}
element_func=function(key,value)
	value=process_string(value)
	return key=="#" and process_url(value) or obj2str(value,p2key[key] or key) 
end
process_string=function(str)
	return string.gsub(str,"(%p)%1%s*(.-)%s*%1%1",element_func)
end

local export=function(doc,filepath)
	local str=obj2str(doc)
	str=process_string(str)
	str=string.gsub(str,"\\([%*%`%$%-%d])","%1")
	local file=io.open(filepath,"w")
	assert(file,"Can't write to file %q,where the content is:\n%s",filepath,str)
	file:write(str)
	file:close()
end

--------------------------------------------------------------------------------------------------------------------------------------------------
-- global functions for call inline or run at compile time
--------------------------------------------------------------------------------------------------------------------------------------------------

local paths={}

local add_path=function(path) push(paths,1,path) end
local real_path=function(path,option) 
	local new_path=path
	local file=io.open(new_path,option)
	if file then file:close() return new_path end
	local n=#paths
	for i=n,1,-1 do
		new_path=format("%s/%s",paths[i],path)
		file=io.open(new_path,option)
		if file then file:close() return new_path end
	end
	assert(file,format("Invalid path %q",path))
end

local get_block=function(key)
	local block=BLOCKS[key]
	assert(block,format("No block named %q",key))
	return block
end

include=function(path)
	local file=io.open(real_path(path))
	local str=file:read("*a")
	file:close()
	return str
end
content=function(key)	return table.concat(key  and get_block(key) or get_top(block),"\n") end
eval=function(str) return eval_string("return "..str) end
ref=function(key) return obj2str(get_block(key),"REF") end

IMPORT=function(path) import(real_path(path)) end
ADD_PATH=function(value) push(paths,value) end
EVAL=eval_string,
CMD=os.execute,
STORE=function(key) 	return rawset(ENV,key,content(key)) end
COMPILE=function(key) 	return rawset(ENV,key,eval(content(key))) end
-------------------------------------------------------------------------------------------------------------------------------------------------
-- main processdure
--------------------------------------------------------------------------------------------------------------------------------------------------

ADD_PATH "/home/yipf/lua-utils/new-org"

local input_file,output_file=...
import(input_file)
local doc=ENV[1]
output_file=output_file or input_file..(ENV["EXT"] or doc.EXT or ".txt")
export(doc,output_file)