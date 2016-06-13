
local patterns={
-- comment line
["COMMENT"]="^%#%~(.-)$",
-- special lines
["SECTION"]="^%**()%*%s*(.-)%s*$",
["PROPS"]="^%#%+(%w+)%:%s*(.-)%s*$",
["SEPERATION"]="^%s*$",
-- block lines
["TABLE"]="^|%s+(.-)%s*|%s*$",
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
	if blocks.CAPTION then blocks[block.CAPTION]=block end
	if blocks.LABEL then blocks[block.LABEL]=block end
	push(blocks,block)
end

local append_block=function(block,stack)
	local top=stack[#stack]
	if top then push(top,block) end
	if block.TYPE=="SECTION" then push(stack,block) 	end
end

local update_block=function(block,stack,blocks)
	if not next(block) then return block end 	-- if block has no child
	register_block(block,blocks)
	append_block(block,stack)
	return {}
end

local str2array=function(str,pat)
	local arr={}
	for w in string.gmatch(pat) do push(arr,w) end
	return arr
end

local file2tree=function(filepath)
	local root={LEVEL=0,TYPE="SECTION"}
	local block=root
	local stack,blocks={},{}
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
			if block.TYPE and block.TYPE~=tp then block=update_block(block,stack,blocks) end -- update block if block is of a different type
			if not block.TYPE then block.TYPE=tp end
			if tp=="UL" or tp=="OL" then 
				line={LEVEL=v1,CAPTION=v2}
			elseif tp=="TABLE" then
				line=str2array(v1,"%s*(.-)%s*|")
			end
			push(block,line) 
		end
	end
	fhandle:close()
	update_block(block,stack,blocks)
	return root,blocks
end

local tree2string
tree2string=function(node,env)
	if type(node)~="table" then return tostring(node) end
	local tp=node.TYPE
	tp= tp=="SECTION" and tp..node.LEVEL or tp
	local hook=env[tp]
	if not hook then return format("[[Invalid type: %q]]",tp) end
	tp=type(hook)
	if tp=="function" then return tostring(hook(node)) end
	local t={}
	for i,v in ipairs(node) do		t[i]=tree2string(v,env)	end
	node.CONTENT=table.concat(t,"\n")
	return (string.gsub(hook,"@(.-)@",node))
end

-------------------------------------------------------------------------------------------------------------------------------
-- inline element processors
-------------------------------------------------------------------------------------------------------------------------------

org_blocks={}
org_template={}

local make_error_string=function(key,value)
	return format("[[ %s: %q]]",key,value)
end

local apply=function(key,...)
	local hook=org_template[key]
	if not hook then return make_error_string("Invalid hook",key) end
	return hook(...) or make_error_string("Error","no return value while process "..key)
end

ref=function(key)
	local block=org_blocks[key]
	if not block then return make_error_string("Invalid block",key) end
	return apply("ref",block)
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

local inline_element2str=function(tag,content)
	if tag=="#" then
		local state,result=loadstring(content)
		return state and result() or format("[[%s]]",result)
	elseif tag=="`" then return apply("quote",content) 
	elseif tag=="*" then return apply("em",content) 
	elseif tag=="*" then return apply("eq",content)
	end
end

process_content=function(content)
	return (string.gsub(content,"([%*%$%#%`])%1%s*(.-)%s*%1%1"))
end
















local eval=function(hook,obj)
	local tp=type(hook)
	return tp=="string" and string.gsub(hook,"@(.-)@",obj) or tp=="function" and hook(obj)
end






local ENV,BLOCKS={},{}

local tag_map={["`"]="quoted",["*"]="em",["$"]="eq"}

local inline_func=function(tag,content)
	local hook=ENV[tag_map[tag] or ""]
	return eval(hook,content)
end

local inline_hooks={
	 ["ref"]=function(t)
		local value=t.VALUE or t[2]
		local block=value and BLOCKS[value]
		return block and eval(ENV["ref"],block) or string.format("[[Invalid block caption or label: %q]]",value)
	end,
	["file"]=function(t)
		local value=t.VALUE or t[2]
		local f=value and io.open(value)
		if not f then return string.format("[[Invalid filename: %q]]",value) end
		value=f:read("*a")
		f:close()
		return value
	end,
	["lua"]=function(t)
		local value=t.VALUE or t[2]
		local func=value and loadstring("return "..value) 
		return func and tostring(func()) or  string.format("[[Invalid lua script: %q]]",value)
	end,
}

local str2args=function(str)
	local args={}
	for w in string.gmatch(str,"%b[]") do	args[#args+1]=string.sub(w,2,-2)	end
	if not args[1] then args[1]=str end
	return args
end

local apply_args=function(args)
	local first=args[1]
	local key,value=string.match(first,"^%s*(%w+)%:%s*(.-)%s*$")
	key=key or first
	local hook=inline_hooks[key] or ENV[key]
	args.VALUE=value
	return eval(hook,args) or  string.format("[[Invalid inline hook for %q]]",key)
end

local miniblock_func=function(str)
	str=string.sub(str,2,-2)
	local args=str2args(str)
	return apply_args(args)
end

local global_process=function(str,env,blocks)
	ENV=env
	BLOCKS=blocks
	str=string.gsub(str,"([%`%*%$])%s*(.-)%s*%1",inline_func)
	str=string.gsub(str,"%b[]",miniblock_func)
	return str
end

org2others=function(org_file)
	local tree,blocks=file2tree(org_file)
	local exporter=tree.EXPORT or "html"
	local env=require("org-templates/"..exporter)
	assert(env,string.format("Invalid exporter: %q",exporter))
	local content=tree2string(tree,env)
	content=global_process(content,env,blocks)
	print(content)
	local output_file=org_file.."."..(env.EXT or exporter)
	print(string.format("Generating %q",output_file))
	local output=io.open(output_file,"w")
	output:write(content)
	output:close()
	if env.post_process then env.post_process(org_file) end
	print("Generating success!")
	return true
end

org2others("test/1.org")

--~ local mode=register(MODES,"org")

--~ block_formater=function()
--~ 	
--~ end