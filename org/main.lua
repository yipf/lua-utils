---------------------------------------------------------------------------------------------
--  input
---------------------------------------------------------------------------------------------
local push,pop=table.insert,table.remove
local match,gsub,gmatch=string.match,string.gsub,string.gmatch

local level,tag,content,top
local push_line=function(line,stack)
	top=pop(stack)
	tag,content=match(line,"^@(%w+)%s+(.-)%s*$") --test if it is a prop line
	if tag and tag~="COMMENT" then
		if tag=="PROPS" then setfenv(loadstring(content),top)() else top[tag]=content end
		push(stack,top)
		return
	end
	level,tag,content=match(line,"^%s*()(%d*[%-%.]+)%s+(.-)%s*$") -- test if it is a list item
	if level then
		level=level-1
		while top.TYPE=="LIST" and top.LEVEL>level do top=pop(stack); end -- pop sub list
		push(stack,top)
		if top.BLOCK or top.LEVEL<level then   -- if the top isn't a list, then add one
			top={TYPE="LIST",SUBTYPE=match(tag,"%d") and "OL" or "UL",LEVEL=level};	
			push(stack[#stack],top);	push(stack,top);	-- append list to its parent and push it to the stack
		end
		push(top,{LEVEL=level,TYPE="LI",CAPTION=content}) -- add current object to its parents
		return
	end
	while not top.BLOCK do top=pop(stack); end -- pop all non-BLOCK items (list itmes)
	level,content=match(line,"^%*+()%s*(.-)%s*$") -- test if current line is a block line
	if level then
		level=level-1
		while top.LEVEL>level do top=pop(stack) end -- pop all BLOCK items whose level >= level
		if top.LEVEL<level then push(stack,top) end 
		if match(content,"%S") then
			top={LEVEL=level,TYPE="SEC",CAPTION=content,BLOCK=true}
			push(stack[#stack],top)
			push(stack,top)
		end
		return 
	end
	push(top,top.TYPE=="SEC" and {TYPE="P",CAPTION=line} or line) -- add current object to its parents
	push(stack,top)
	return
end

local file2doc=function(path,doc)
	doc=doc or {TYPE="SEC",LEVEL=0,BLOCK=true,CAPTION="DOCUMENT"}
	local stack={doc}
	for line in io.lines(path) do  push_line(line,stack)	end
	return doc
end

---------------------------------------------------------------------------------------------
--  output
---------------------------------------------------------------------------------------------

local temp={}
local tbl2str=function(tbl,converter,s,e,sep)
	for i=s,e do temp[i]=converter(tbl[i]) end
	return table.concat(temp,sep or "\n",s,e)
end

local counters={0}
local counter=function(class,section_realtive)
	local id=counters[class]
	if type(class)=="number" then 
		for i=class+1,#counters do counters[i]=0 end
	end
	counters[class]=id and id+1 or 1
end

local gen_toc
gen_toc=function(node,toc,id_func,sep)
	local tp
	if type(node)=="table" and node.BLOCK then 
		tp=node.TYPE
		if tp=="SEC" then
			counter(node.LEVEL)
			node.ID=tbl2str(counters,id_func,1,node.LEVEL,sep)
		else
			counter(tp)
			node.ID=counters[tp]
		end
		push(toc,node) 
		toc[node.CAPTION]=node
		for i,v in ipairs(node) do gen_toc(v,toc,id_func,sep) end
	end
	return toc
end

local eval=function(func,obj)
	return type(func)=="function" and func(obj) or type(func)=="string" and gsub(func,"@(.-)@",obj)
end

local node2str
node2str=function(node,str)
	if type(node)~="table" then return node end
	local t={}
	for i,v in ipairs(node) do 	t[i]=node2str(v) end
	node.VALUE=table.concat(t,"\n")
	str=eval(ENV[node.TYPE=="SEC" and node.LEVEL or node.TYPE],node)
	return str or string.format([[((Invalid type: %q))]],node.TYPE)
end

local tostring=tostring
local execute_func=function(tag,str)	
	local i=0
	local obj={[0]=str,["0"]=str}
	for w in gmatch(str.."|","%s*(.-)%s*|") do i=i+1; obj[i]=w;	obj[tostring(i)]=w end
	return eval(ENV[tag],obj) 
end

local doc2file=function(doc,path,id_func,sep)
	DOC=doc
	gen_toc(doc,BLOCKS,id_func,sep)
	local str=node2str(doc)
	str=gsub(str,"([%`%#%*%$])%1%s*(.-)%s*%1%1",execute_func)
	if path then
		local f=io.open(path,"w")
		assert(f,"Invalid filepath:\t"..path)
		f:write(str); 	f:close();	
	else
		print("At least one file path should be given!")
	end
	return str
end

---------------------------------------------------------------------------------------------
--  interface
---------------------------------------------------------------------------------------------
local execute_cmd=function(obj)
	local k,v=match(obj[1],"^%s*(%w+)%s*%:%s*(.-)%s*$")
	k=ENV[k]
	if k then return k(v,unpack(obj,3)) end
end

BLOCKS={}

ENV={
	-- commands
	["lua"]=function(str) return loadstring("return "..str)() end,
	["file"]=function(path,str) 
		local f=io.open(path)	
		if f then str=f:read("*a");	f:close(); end
		return str
	end,
	["ref"]=function(key)
		local node=BLOCKS[key]
		return node and eval(ENV["ref-link"],node) or string.format([[Invalid reference: %q]],key)
	end,
	-- styles
	["LIST"]=function(node)
		return eval(ENV[node.SUBTYPE],node)
	end,
	[0]="@CAPTION@\n@VALUE@",
	[1]="@ID@ @CAPTION@\n@VALUE@",
	[2]="@ID@ @CAPTION@\n@VALUE@",
	[3]="@ID@ @CAPTION@\n@VALUE@",
	["#"]=function(obj) return execute_cmd(obj) end,
	["`"]=[["@0@"]],
	["*"]=[[**@0@**]],
}

local format=string.format
-- default template directory
local TEMP_DIR_FMT="/home/yipf/lua-utils/org/templates/%s.lua"
-- setup filepaths
local template,input=...
assert(template,"At least a filepath must be given!")
if not input then input=template; template="html" end
local output=format("%s-%s.%s",match(input,"^(.-)%.?[^%.]*$"),template,ENV.EXT or template)
-- setup ENV
print(format("Setting up Envrionment of %q",template))
local t=dofile(format(TEMP_DIR_FMT,template))
for k,v in pairs(t) do 	ENV[k]=v end
-- do converter
local default_id=function(i) return i end
print(format("Reading from file: %q",input))
local doc=file2doc(input)
print(format("Writing to file: %q",output))
doc2file(doc,output,ENV.id_func or default_id,ENV.SEP or " . ")




