require "global"

local keycode2char={}
for i=0,255 do keycode2char[i]=char(i)end
keycode2char[65289]="TAB"
keycode2char[65288]="BACKSPACE"
keycode2char[65293]="ENTER"
keycode2char[32]="SPC"
keycode2char[65361]="LEFT"
keycode2char[65362]="UP"
keycode2char[65363]="RIGHT"
keycode2char[65364]="DOWN"

OnOpen=function()
	local hooks={GLOBAL}
	hooks[#hooks+1]=MODES[props["Language"]]
	buffer.HOOKS=hooks
	buffer.top=0
end

local append_minibuffer=function(minibuffer,obj)
	local top=minibuffer.top
	top=top+1
	minibuffer[top]=obj
	minibuffer.top=top
end

local concat=table.concat
local minibuffer2key=function(minibuffer)	
	local top=minibuffer.top
	return top>0 and concat(minibuffer,nil,1,top) 
end

local key2hook=function(key,hooks)
	local hook
	for i=#hooks,1,-1 do
		hook=hooks[i][key]
		if hook then return hook end
	end
end

OnKey=function(keycode,shift,ctrl,alt)
	local minibuffer,hooks=buffer,buffer.HOOKS
	local top=minibuffer.top -- get previous
	if ctrl then append_minibuffer(minibuffer,"C-") end
	if alt then append_minibuffer(minibuffer,"M-") end
	append_minibuffer(minibuffer,keycode2char[keycode] or "")
	local key=minibuffer2key(minibuffer)
	local hook=key2hook(key,hooks)
	if hook==PREFIX then append_minibuffer(minibuffer,SEP) return true end
	minibuffer.top=0 -- clear minibuffer
	if hook then -- if hook is a callable function
		if not hook() then return false end
	else -- otherwise, echo error message
		if top==0 then return false end
		message("%q is not defined!",key)
	end
	return true
end

local matchers={["("]=")",["["]="]",["{"]="}",["\""]="\""}  
OnChar=function(ch)
	local m=matchers[ch]
	if m then insert(m) end
end

OnStyle=function(styler)
	local fn=get_lexer(props['Language'])
	if fn then fn(styler) end   
end