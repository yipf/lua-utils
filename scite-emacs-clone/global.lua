-- global functions

register=function(tbl,key)
	local obj=tbl[key]
	if not obj then obj={} tbl[key]=obj end
	return obj
end

reset_pos=function(pos)
	pos=pos or editor.CurrentPos
	editor:SetEmptySelection(pos)
	editor:ScrollCaret()
end

set_sel=function(s,e) editor:SetSel(s,e) end 
get_sel=function() return editor:GetSelText() end
replace_sel=function(text) editor:ReplaceSel(text) end

format,char,byte,sub=string.format,string.char,string.byte,string.sub

message=function(fmt,...)	output:SetText(format(fmt,...)) end

eval_lua=function(str) return loadstring(str)() end
eval_cmd=function(cmd) return io.popen(cmd):read("*a") end

-- pop-up function
pop_list=function(len,str,sep)
	if sep then editor.AutoCSeparator=string.byte(sep) end
	editor.AutoCAutoHide=false
	editor:AutoCShow(len,str)
end

search_prev=function(pat,pos)
	if pos then editor:GotoPos(pos) end
	editor:SearchAnchor()
	return editor:SearchPrev(SCFIND_REGEXP,pat)
end

search_next=function(pat,pos)
	if pos then editor:GotoPos(pos) end
	editor:SearchAnchor()
	return editor:SearchNext(SCFIND_REGEXP,pat)
end

do_menu=function (id)  scite.MenuCommand(id) end
insert=function(text,pos) editor:InsertText(pos or -1,text) end

position2line=function(pos) return editor:LineFromPosition(pos or editor.CurrentPos) end
line2position=function(line) return editor:PositionFromLine(line or position2line(editor.CurrentPos)) end

get_anchor=function() return buffer.anchor end
set_anchor=function(pos) buffer.anchor=pos or editor.CurrentPos end
clear_anchor=function() buffer.anchor=nil end

local folder_header_level=SC_FOLDLEVELBASE+ SC_FOLDLEVELHEADERFLAG

get_line_folder_level=function(line) 
	local level=editor.FoldLevel[line or position2line()] 
	return level,level>=folder_header_level
end

id=function(self) return self end
make_factory=function(key2value,container)
	key2value=key2value or id
	container=container or {}
	return function(key)
		local value=container[key]
		if not value then
			value=key2value(key)
			container[key]=value
		end
		return value
	end
end

-- global variables
GLOBAL={}
MODES={}
LEXERS={}

ANYTHING=function() return true end
PREFIX=ANYTHING
SEP=" "

obj2function=function(obj)
	local tp=type(obj)
	if tp=="number" then
		return function() scite.MenuCommand(obj) return true end
	elseif tp=="string" then
		return loadstring(format("editor:%s() return true",obj))
	end
	return obj
end
normal_functions=make_factory(obj2function)

bind_key=function(mode,key,obj,info)
	mode=mode or GLOBAL
	local sub=string.sub
	for e in string.gmatch(key,"%S+()%s") do
		mode[sub(key,1,e-1)]=PREFIX
	end
	obj=obj and normal_functions(obj)
	mode[key]=obj
	if info then -- if there are help info
		info=format("%q : %s",key,info)
		bind_key(mode,"C-h "..key,function() message(info) return true end)
	end
	return obj
end

global_bind_key=function(key,obj,info)
	return bind_key(GLOBAL,key,obj,info)
end

expand_word=obj2function(IDM_ABBREV)
expand_fold=obj2function(IDM_EXPAND)

local FUNCTIONS={}

func2intactive=function(func)
	return function()
		buffer.session=func
		set_anchor(editor.CurrentPos)
		return true
	end
end
intactive_functions=make_factory(func2intactive)

obj2nav=function(obj)
	local f=obj2function(obj)
	return function()
		f()
		local pos=get_anchor()
		if pos and editor.SelectionEmpty then set_sel(pos,editor.CurrentPos) end
		return true
	end
end
navigation_functions=make_factory(obj2nav)