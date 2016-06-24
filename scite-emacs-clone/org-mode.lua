
local patterns={
-- comment line
["COMMENT"]="^%#%~(.-)$",
-- special lines
["SECTION"]="^%**()%*%s*(.-)%s*$",
["PROPS"]="^%#%+(%w+)%:%s*(.-)%s*$",
["SEPERATION"]="^%s*$",
-- block lines
["TABLE"]="^|[%s%-]+(.-[%s%-]+|)%s*$",
["UL"]="^%s+()[%*%-]-%s+(.-)%s*$",
["OL"]="^%s+()[%(%[]-%w+[%)%]%.]-%s+(.-)%s*$",
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
	pat=pat or "%s*([^|]-)%s+|"
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
				line=str2array(v1,"%s*([^|]-)%s+|")
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

local process_line=function(line)
	return (string.gsub(line,"([%*%$%#%`])%1%s*(.-)%s*%1%1",inline_element2str))
end

process_content=function(content)
	return (string.gsub(content,"([^\n]*)",process_line))
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
--~ 	if tp=="PARAGRAPH" or tp=="UL" or tp=="OL" then 
		local s=1
		for ss,tag,ee in string.gmatch(text,"()([%`%#%$%*])%2%s*.-%s*%2%2()") do
			editor:SetStyling(ss-s,style)
			editor:SetStyling(ee-ss,styles[tag])
			s=ee
		end
		editor:SetStyling(length-s+1,style)
		return
--~ 	end
--~ 	editor:SetStyling(length, style)	
end

local exts="*.org;"

props["file.patterns.org"]=exts
props["lexer.$(file.patterns.org)"]=language

make_line_lexer(language,line_function)

-------------------------------------------------------------------------------------------------------------------------------
--setting up
-------------------------------------------------------------------------------------------------------------------------------

set_command("$(file.patterns.org)","go","org2others $(FileNameExt)","script")
props["abbreviations.$(file.patterns.org)"]="$(SciteUserHome)/org_abbrev.properties"

-------------------------------------------------------------------------------------------------------------------------------
--helper functions for editing
-------------------------------------------------------------------------------------------------------------------------------
local get_line_type_by_line=function(line)
	local text=editor:GetLine(line)
	return text,get_line_type(text)
end

local test_similar_lines=function(lines,TP,s,e,d)
	local text,tp
	d=d or 1
	for i=s,e,d do
		text,tp=get_line_type_by_line(i)
		if tp~=TP then return i-d end
		lines[i]=text
	end
	return e
end

local select_similar_lines=function(line) -- select similar lines with same format
	line=line or position2line()
	local lines={}
	local text,tp=get_line_type_by_line(line)
	local lines={[line]=text}
	local S,E=test_similar_lines(lines,tp,line-1,0,-1),	test_similar_lines(lines,tp,line+1,editor.LineCount-1,1)
	return tp,S,E,lines
end

local mode=register(MODES,language)

local get_max_widths=function(lines,s,e)
	local len,max=string.len,math.max
	local maxs,row={}
	for i=s,e do
		row=string.sub(lines[i],2) -- drop the first `|'
		row=str2array(row,"%s*([^|]-)%s+|")
		if row[1] then
			for ii,v in ipairs(row) do
				v=len(v)
				maxs[ii]=maxs[ii] and max(maxs[ii],v) or v
			end
		end
		lines[i]=row
	end
	return lines,maxs
end

local reprint_cells=function(row,maxs)
	local sep
	if row[1] then
		for i,v in ipairs(maxs) do			row[i]=string.format(string.format("%%-%ds",v),row[i] or "")		end
		return "| "..table.concat(row," | ").." |"
	else
		if not sep then
			for i,v in ipairs(maxs) do				row[i]=string.rep("-",v)			end
			sep="|-"..table.concat(row,"-+-",1,#maxs).."-|"
		end
		return sep
	end
end

local reprint_rows=function(lines,maxs,s,e)
	for i=s,e do		lines[i]=reprint_cells(lines[i],maxs)	end
	return lines
end

reformat_table=function(lines,S,E)
	local maxs={}
	lines,maxs=get_max_widths(lines,S,E)
	lines=reprint_rows(lines,maxs,S,E)
	return table.concat(lines,"\n",S,E)
end

local list_row2id_content=function(line)
	return string.match(line,"^%s+(%p*)(%w+)(%p)%s+(.-)%s*$")
end

reformat_orderlist=function(lines,S,E)
	local row=lines[S]
	local p1,id,p2,content=string.match(row,"^%s+(%p*)(%w+)(%p)%s+(.-)%s*$")
	if tonumber(id) then
		id=-S+1
		for i=S,E do
			row=lines[i]
			lines[i]=string.gsub(row,"^%s+%p*%w+%p%s+(.-)%s*",string.format("\t%s%d%s\t%%1",p1,id+i,p2))
		end
	else
		id=string.byte("a")-S
		for i=S,E do
			row=lines[i]
			lines[i]=string.gsub(row,"^%s+%p*%w+%p%s+(.-)%s*",string.format("\t%s%s%s\t%%1",p1,string.char(id+i),p2))
		end
	end
	return table.concat(lines,"",S,E)
end

reformat_lines=function()
	local pos=editor.CurrentPos
	local tp,S,E,lines=select_similar_lines(position2line(pos))
	local str= tp=="TABLE" and reformat_table(lines,S,E) or tp=="OL" and reformat_orderlist(lines,S,E)
	if lines then
		set_sel(line2position(S),line2position(E+1))
		replace_sel(str)
	end
	reset_pos(pos)
	return true
end

bind_key(mode,"C-c C-c",reformat_lines)
