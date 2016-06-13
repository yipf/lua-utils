
local patterns={
-- comment line
["COMMENT"]="^%#%~(.-)$",
-- special lines
["SECTION"]="^%**()%*%s*(.-)%s*$",
["PROPS"]="^%#%+(%w+)%:%s*(.-)%s*$",
["SEPERATION"]="^%s*$",
-- block lines
["TABLE"]="^|[%s%-]+(.-[%s%-]+|)%s*$",
["UL"]="^%s+()%p+%s+(.-)%s*$",
["OL"]="^%s+()%p*%w+%p%s+(.-)%s*$",
}

local get_line_type=function(line)
	local v1,v2
	local match=string.match
	for k,v in pairs(patterns) do
		v1,v2=match(line,v)
		if v1 then return k,v1,v2 end
	end
	return "PARAGRAPH"
end

local push,pop=table.insert,table.remove

local register_block=function(block,blocks)
	if block.CAPTION then blocks[block.CAPTION]=block end
	if block.LABEL then blocks[block.LABEL]=block end
	push(blocks,block)
	return block
end

local append_block=function(block,stack)
	local top=stack[#stack]
	if top then push(top,block) end
	if block.TYPE=="SECTION" then push(stack,block) 	end
	return block
end

local update_block=function(block,stack,blocks)
	if not next(block) then return block end 	-- if block is empty return it
	block=register_block(block,blocks)
	block=append_block(block,stack)
	return {}
end

local str2array=function(str,pat)
	local arr={}
	for w in string.gmatch(str,pat) do push(arr,w) end
	return arr
end

local file2tree=function(filepath,blocks)
	local root={LEVEL=0,TYPE="SECTION"}
	local block=root
	local stack={}
	local tp,v1,v2
	local fhandle=io.open(filepath)
	assert(fhandle,string.format("Can't open filepath: %q",filepath))
	for line in fhandle:lines() do
		tp,v1,v2=get_line_type(line)
		if tp=="SEPERATION" then
			block=update_block(block,stack,blocks) -- update current block
		elseif tp=="SECTION" then
			block=update_block(block,stack,blocks)  -- update current block
			while #stack>v1 do pop(stack) end -- pop SECTION blocks whose level>=current level
			if string.len(v2)>0 then block.TYPE,block.LEVEL,block.CAPTION=tp,v1,v2 end -- if caption is not empty then set current block a new SECTION 
		elseif tp=="PROPS" then
			block[v1]=v2
		elseif tp~="COMMENT" then	-- other blocks, if not comment, 
			if tp~="PARAGRAPH" and block.TYPE and block.TYPE~=tp then -- paragraphs are children of any block including itself
				block=update_block(block,stack,blocks)
			end
			if not block.TYPE then block.TYPE=tp end
			if tp=="UL" or tp=="OL" then 
				line={LEVEL=v1,CAPTION=v2}
			elseif tp=="TABLE" then
				line=str2array(v1,"%s*(.-)%s+|")
			end
			push(block,line) 
		end
	end
	fhandle:close()
	update_block(block,stack,blocks)
	return root,blocks
end

local make_error_string=function(key,value)
	return string.format("[[%s: %q]]",key,value)
end

local tree2string
tree2string=function(node,env)
	if type(node)~="table" then return tostring(node) end
	local tp=node.TYPE
	tp= tp=="SECTION" and tp..node.LEVEL or tp
	local hook=org_template[tp]
	if not hook then return make_error_string("Invalid type",tp) end
	if type(hook)=="function" then return hook(node) end
	local t={}
	for i,v in ipairs(node) do		t[i]=tree2string(v,env)	end
	node.CONTENT=table.concat(t,"\n")
	return (string.gsub(hook,"@(.-)@",node))
end

-------------------------------------------------------------------------------------------------------------------------------
-- inline element processors, table of contents generator and ...
-------------------------------------------------------------------------------------------------------------------------------

org_template={}
org_blocks={}

local apply=function(key,obj)
	local hook=org_template[key]
	if not hook then return make_error_string("Invalid hook",key) end
	return (string.gsub(hook,"@(.-)@",obj))
end

ref=function(key)
	local block=org_blocks[key]
	if not block then return make_error_string("Invalid block",key) end
	return apply("ref",block)
end

img=function(url,desc)
	local obj={URL=url,DESC=desc or url}
	return apply("img",obj)
end

file=function(path)
	local f=io.open(path)
	if not f then return make_error_string("Invalid filepath",file) end
	local str=f:read("*a")
	f:close()
	return str
end

link=function(url,caption)
	local tp,address=string.match(url,"^%s*(%w+)%s*:%s*(.-)%s*$")
	if not tp then return make_error_string("Invalide url",url) end
	local obj={URL=address,CAPTION=caption or url} 
	return apply(tp,obj)
end

toc=function(...)
	local tocs={...}
	for i,tp in ipairs(tocs) do
		local items={CAPTION=tp}
		for i,v in ipairs(org_blocks) do
			if v.TYPE==tp then push(items,apply("toc-item",v)) end
		end
		items.CONTENT=table.concat(items)
		tocs[i]=apply("toc-block",items)
	end
	tocs.CAPTION="Table of Contents"
	tocs.CONTENT=table.concat(tocs)
	return apply("toc",tocs)
end

local inline_element2str=function(tag,content)
	if tag=="#" then
		local state,result=pcall(loadstring,"return "..content)
		if state then return result() or ""
		else return make_error_string("Error",tostring(result)) end
	elseif tag=="`" then return apply("quote",content) 
	elseif tag=="*" then return apply("em",content) 
	elseif tag=="$" then return apply("eq",content)
	end
end

process_content=function(content)
	return (string.gsub(content,"([%*%$%#%`])%1%s*(.-)%s*%1%1",inline_element2str))
end

generate_id=function(blocks,sep)
	local counters,tp,level,id={}
	for i,block in ipairs(blocks) do
		tp=block.TYPE
		if tp=="SECTION" then
			level=block.LEVEL
			for i=level+1,#counters do counters[i]=0 end
			id=counters[level]
			if not id then id=0 end
			counters[level]=id+1
			block.ID=table.concat(counters,sep or ".",1,level)
		else
			id=counters[tp]
			if not id then id=0 end
			counters[tp]=id+1
			block.ID=counters[tp]
		end
	end
	return blocks
end

org2others=function(org_file)
	org_blocks={}
	local tree=file2tree(org_file,org_blocks)
	org_blocks=generate_id(org_blocks)
	local exporter=tree.EXPORT or "html"
	org_template=require("org-templates/"..exporter)
	assert(org_template,string.format("Invalid exporter: %q",exporter))
	local content=tree2string(tree,org_template)
	content=process_content(content)
	local output_file=org_file.."."..(org_template.EXT or exporter)
	print(string.format("Generating %q",output_file))
	local output=io.open(output_file,"w")
	output:write(content)
	output:close()
	if org_template.post_process then env.post_process(org_file) end
	print("Generating success!")
	return true
end

--~ org2others("test/1.org")

-------------------------------------------------------------------------------------------------------------------------------
-- lexer
-------------------------------------------------------------------------------------------------------------------------------
require "global"

local language="script_org"
local style_func=make_style_register_function(language)

local styles={
	["PARAGRAPH"]=0,
	["`"]=style_func"italics,$(colour.string)",
	["#"]=style_func"$(font.monospace),$(colour.keyword),underlined",
	["$"]=style_func"italics,$(colour.number)",
	["*"]=style_func"bold",
	["SECTION1"]=style_func"$(colour.keyword),bold",
	["SECTION2"]=style_func"$(colour.string),bold",
	["SECTION3"]=style_func"$(colour.char),bold",
	["SECTION4"]=style_func"$(colour.number),bold",
	["SECTION5"]=style_func"bold",
	["SECTION6"]=style_func"bold",
	["SECTION7"]=style_func"bold",
	["SECTION8"]=style_func"bold",
	["TABLE"]=style_func"$(font.monospace),$(colour.keyword)",
	["PROPS"]=style_func"$(font.monospace),$(colour.comment)",
	["COMMENT"]=style_func"$(font.monospace),$(colour.comment)",
}

local line_function=function(line)
	local text,length=editor:GetLine(line),editor:PositionFromLine(line+1) - editor:PositionFromLine(line)
	local tp,v1,v2=get_line_type(text)	
	if tp=="SECTION" then
		tp=tp..v1
		set_line_level(line,v1,true)
	else
		set_line_level(line,20,true)
	end
	local style=styles[tp] or 0
	if tp=="PARAGRAPH" then 
		local s=1
		for ss,tag,ee in string.gmatch(text,"()([%`%#%$%*])%2.-%2%2()") do
			editor:SetStyling(ss-s,style)
			editor:SetStyling(ee-ss,styles[tag])
			s=ee
		end
		editor:SetStyling(length-s+1,0)
		return
	end
	editor:SetStyling(length, style)	
end

local exts="*.org;"

props["file.patterns.org"]=exts
props["lexer.$(file.patterns.org)"]=language

set_command("$(file.patterns.org)","go","org2others $(FileNameExt)","script")

make_line_lexer(language,line_function)


