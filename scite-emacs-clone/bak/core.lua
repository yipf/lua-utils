local editor=editor

local keycode2char={}
for i=0,255 do
	keycode2char[i]=string.char(i)
end
keycode2char[65289]="TAB"
keycode2char[65288]="BACKSPACE"
keycode2char[65293]="ENTER"
keycode2char[32]="SPC" 
keycode2char[65361]="LEFT"
keycode2char[65362]="UP"
keycode2char[65363]="RIGHT"
keycode2char[65364]="DOWN"

local keycode2str=function(keycode,ctrl,meta)
	local key=keycode2char[keycode] or ""
	return ctrl and (meta and "C-M-"..key or "C-"..key) or meta and "M-"..key or key 
end

local robust_get=function(obj,key)
	local value=obj[key]
	if not value then value={} obj[key]=value end
	return value
end

local type=type
OnKey=function(keycode,shift,ctrl,alt)
--~ 	print(keycode)
	local key=keycode2str(keycode,ctrl,alt)
	local hook=buffer.hooks[key]
	local tp=type(hook) 
	if tp=="function" then  -- if key is a function, do the function
		buffer.hooks=buffer.HOOKS -- reset hooks to default
		return hook() 
	end
	if tp=="table" then  -- if key is a prefix, move to next hooks
		buffer.hooks=hook
		return true
	end
	return false
end

local matchers={["("]=")",["["]="]",["{"]="}",["\""]="\""}  
OnChar=function(ch)
	local m=matchers[ch]
	if m then editor:InsertText(-1,m) end
end

local modes={["GLOBAL"]={}}

local props=props
OnOpen=function()
	local mode=modes[props["Language"]] or modes["GLOBAL"]
	buffer.HOOKS=mode
	buffer.hooks=mode
	buffer.info={top=0}
end

----------------------------------------------------------------------------------------------------------
-- extension function
----------------------------------------------------------------------------------------------------------

-- http://www.scintilla.org/CommandValues.html

local do_menu=scite.MenuCommand
menuid2function=function(id)
	return function() do_menu(id) return true end
end

funcname2function=function(name)
	local func=loadstring(string.format("editor:%s() 	return true",name))
	return func
end

local type=type
value2function=function(obj)
	local tp=type(obj)
	return (tp=="number") and menuid2function(obj) or (tp=="string") and funcname2function(obj) or obj
end

local gmatch,sub=string.gmatch,string.sub
bind_key=function(mode_name,key_str,obj)
	local hooks=robust_get(modes,mode_name)
	local s=1
	for key,pos in gmatch(key_str,"(%S+)%s+()") do 
		hooks=robust_get(hooks,key)
		s=pos
	end
	hooks[sub(key_str,s,-1)]=value2function(obj)
	return func
end

global_bind_key=function(key_str,func)
	return bind_key("GLOBAL",key_str,func)
end

local a_code,z_code,A_code,Z_code=string.byte("a"),string.byte("z"),string.byte("A"),string.byte("Z")
local is_char=function(ch)
	return (ch>=a_code) and (ch<=z_code) or (ch>=A_code) and (ch<=Z_code)
end

local process_info=function(info,pos)
	local top=info.top
	info[top]=pos
	return pcall(unpack(info,1,top))
end

get_info=function(init)
	local info=buffer.info	
	if not info then 
		info={top=1}
		buffer.info=info
	elseif init then
		info.top=1
	end
	return info
end

expand_word=menuid2function(IDM_ABBREV)
expand_fold=menuid2function(IDM_EXPAND)

local smart_tab=function()
	local pos=editor.CurrentPos
	local info=get_info()
	if info and info.top>1 then return process_info(info,pos) end
	if editor.SelectionEmpty then
		if pos==editor:PositionFromLine(editor:LineFromPosition(pos)) then
			return expand_fold()
		elseif pos>0 and is_char(editor.CharAt[pos-1]) then
			return expand_word()
		end
	end
	return false -- default tab
end
global_bind_key("TAB",smart_tab)     

local format=string.format
msg=function(fmt,...)
	output:SetText(format(fmt,...))
end

get_anchor=function()	return buffer.anchor end
set_anchor=function(pos) buffer.anchor=pos end
clear_anchor=function() buffer.anchor=nil end
	
-- pop-up function
pop_list=function(len,str,sep)
	if sep then editor.AutoCSeparator=string.byte(sep) end
	editor.AutoCAutoHide=false
	editor:AutoCShow(len,str)
end

search_regexp_prev=function(pat,pos)
	if pos then editor:GotoPos(pos) end
	editor:SearchAnchor()
	return editor:SearchPrev(SCFIND_REGEXP,pat)
end

search_regexp_next=function(pat,pos)
	if pos then editor:GotoPos(pos) end
	editor:SearchAnchor()
	return editor:SearchNext(SCFIND_REGEXP,pat)
end


