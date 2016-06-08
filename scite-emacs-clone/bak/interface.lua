require "core"

global_bind_key("C-s",IDM_INCSEARCH)
global_bind_key("C-r",IDM_REPLACE)
global_bind_key("C-x k",IDM_CLOSE)
global_bind_key("C-x C-f",IDM_OPEN)
global_bind_key("C-x C-s",IDM_SAVE)
global_bind_key("C-x C-w",IDM_SAVEAS)
global_bind_key("C-x C-c",IDM_QUIT)
global_bind_key("C-x o",IDM_NEXTFILE)

global_bind_key("C-v","PageDown")
global_bind_key("M-v","PageUp")

global_bind_key("C-w","Cut")
global_bind_key("C-y","Paste")
global_bind_key("M-w","Copy")
global_bind_key("M-y","Paste")

global_bind_key("C-i","ScrollCaret")
global_bind_key("C-j","NewLine")
global_bind_key("M-j","NewLine")

global_bind_key("C-/","Undo")
global_bind_key("C-\\","Redo")

global_bind_key("C-k","DelLineRight")
global_bind_key("C-BACKSPACE","DelLineLeft")

--~ global_bind_key("C-d","DelLineLeft")
--~ global_bind_key("C-K","DelLineLeft")

global_bind_key("C-x h","SelectAll")

-- http://www.scintilla.org/PaneAPI.html

set_sel=function(s,e) editor:SetSel(s,e) end
get_sel_text=function() return editor:GetSelText() end
replace_sel=function(text) editor:ReplaceSel(text) end

local make_move_function=function(mover)
	mover=type(mover)~="function" and value2function(mover) or mover
	return function()
		mover()
		local anchor=get_anchor()
		if anchor then set_sel(anchor,editor.CurrentPos) end
		return true
	end
end

local set_anchor=function()
	set_anchor(editor.CurrentPos)
	return true
end
global_bind_key("C-@",set_anchor)

local give_up=function(pos)
	buffer.hooks=buffer.HOOKS
	buffer.anchor=nil
	get_info(true)
	editor:Cancel()
	editor:SetEmptySelection(editor.CurrentPos)
	trace("\nQuit!")
	return true
end
global_bind_key("C-g",give_up)

global_bind_key("M-<",make_move_function"DocumentStart")
global_bind_key("M->",make_move_function"DocumentEnd")

global_bind_key("C-a",make_move_function"Home")
global_bind_key("C-e",make_move_function"LineEnd")
global_bind_key("C-p",make_move_function"LineUp")
global_bind_key("C-n",make_move_function"LineDown")
global_bind_key("C-f",make_move_function"CharRight")
global_bind_key("C-b",make_move_function"CharLeft")

global_bind_key("C-[",make_move_function"ParaUp")
global_bind_key("C-]",make_move_function"ParaDown")
global_bind_key("M-b",make_move_function"WordLeft")
global_bind_key("M-f",make_move_function"WordRight")

global_bind_key("M-d","DelWordRight")
global_bind_key("M-BACKSPACE","DelWordLeft")

local sel_paragraph=function()
	editor:ParaDown()
	editor:ParaUpExtend()
	return true
end
global_bind_key("M-h",sel_paragraph)

local status_word_char=function()
	local text= editor.SelectionEmpty and editor:GetText() or get_sel_text()
	local word_count,char_count=0,0
	for s,e in string.gmatch(" "..text,"%s+()[a-zA-Z%-]+()") do 
		word_count=word_count+1 
		char_count=char_count+e-s
	end
	msg("Text include:%10d words %10d characters.",word_count,char_count)
	return true
end
global_bind_key("M-=",status_word_char) 

make_interactive_func=function(hook)
	return function()
		print("Start continuative session!")
		local info=buffer.info
		local pos=editor.CurrentPos
		info[1]=hook
		info[2]=pos
		info.top=3
		return true
	end
end

eval_lua=function(str)	
	local func=loadstring(str)
	return func and func()
end
eval_cmd=function(cmd) return io.popen(cmd):read("*a") end

local execute_lua=function(s,e)
	set_sel(s,e)
	replace_sel(eval_lua(get_sel_text()) or "")
	return true
end
global_bind_key("M-x",make_interactive_func(execute_lua)) 

local LS_FMT="ls -d -p %q*"
local suggest_file=function(s,e)
	local path= s==e and "./" or editor:textrange(s,e)
	path=eval_cmd(string.format(LS_FMT,path))
	pop_list(e-s,path,"\n")
	return true
end
global_bind_key("M-/",make_interactive_func(suggest_file)) 

local SPELL_WORD_FMT="echo %q | aspell -a"
local SPELL_WORD_PAT="^.-:%s*(%w.-)%s*$"

local get_candidate=function(word) -- get word candidates to check if it is well-spelled 
	local candidate=eval_cmd(string.format(SPELL_WORD_FMT,word))
	candidate=string.match(candidate,SPELL_WORD_PAT)
	candidate=candidate and string.gsub(candidate,",%s+","\n")
	return candidate
end

local sel_word=function(pos)
	pos=pos or editor.CurrentPos
	set_sel(editor:WordStartPosition(pos, true),editor:WordEndPosition(pos, true))
end

check_word=function()
	local word
	if editor.SelectionEmpty then sel_word(editor.CurrentPos) end
	word=get_sel_text()
	local candidate=get_candidate(word)
	if candidate then
		pop_list(string.len(word),candidate,"\n")
	else
		msg("%q is right!",word)
	end
	return true
end
global_bind_key("M-$",check_word) 

next_error_word=function()
	local s,word,candidate
	repeat
		s=search_regexp_next("\\w+",editor.SelectionEnd)
		if s<0 then return true end
		word=get_sel_text()
		candidate=get_candidate(word)
	until candidate
	pop_list(string.len(word),candidate,"\n")
	return true
end

prev_error_word=function()
	local s,word,candidate
	repeat
		s=editor.SelectionStart
		editor:WordLeft() 
		if s==editor.CurrentPos then return true end
		editor:WordRightEndExtend()
		word=get_sel_text()
		candidate=get_candidate(word)
	until candidate
	pop_list(string.len(word),candidate,"\n")
	return true
end
global_bind_key("C-UP",prev_error_word) 
global_bind_key("C-DOWN",next_error_word) 

show_dict=function()
	if editor.SelectionEmpty then sel_word(editor.CurrentPos) end
	local word=get_sel_text()
	msg(eval_cmd(string.format("sdcv -n %s",word)))
	return true
end
global_bind_key("M-%",show_dict) 

output_linedown=function()
	output:LineDown()
	output:Home()
	output:LineEndExtend()
	return true
end
global_bind_key("C-M-n",output_linedown) 

output_lineup=function()
	output:LineUp()
	output:Home()
	output:LineEndExtend()
	return true
end
global_bind_key("C-M-p",output_lineup) 

insert_output_text=function()
	editor:insert(-1,output:GetSelText())
	return true
end
global_bind_key("C-M-i",insert_output_text)   

sentence_head=function(pos)
	pos=pos or editor.CurrentPos
	if pos<1 then return true end
	pos=search_regexp_prev("[;\\.]\\s+",pos-1)
	if pos>0 then
		editor:SetEmptySelection(editor.SelectionEnd)
	end
	return true
end

sentence_end=function(pos)
	if pos then editor:GotoPos(pos) end
	pos=search_regexp_next("[;\\.]\\s+")
	if pos>0 then
		editor:SetEmptySelection(editor.SelectionEnd)
	end
	return true
end

global_bind_key("M-a",sentence_head)   
global_bind_key("M-e",sentence_end)   

kill_sentence_to_end=function()
	local s=editor.CurrentPos
	local e=search_regexp_next("[;\\.\\s]\\s+")
	if s<e then
		set_sel(s,editor.SelectionEnd)
		replace_sel("")
	end
	return true
end

kill_sentence_to_head=function()
	local e=editor.CurrentPos
	if e<1 then return true end
	local s=search_regexp_prev("[;\\.]\\s+",e-1)
	if s>0 and s<e then
		set_sel(editor.SelectionEnd,e)
		replace_sel("")
	end
	return true
end

global_bind_key("M-k",kill_sentence_to_end)   
global_bind_key("M-BACKSPACE",kill_sentence_to_head)   

prev_brace=function()
	local e=search_regexp_prev("[(\\[{]")
	if e>=0 then editor:SetEmptySelection(e) end
	return true
end

next_brace=function()
	local e=search_regexp_next("[)}\\]]")
	if e>=0 then editor:SetEmptySelection(e+1) end
	return true
end

global_bind_key("M-[",prev_brace)   
global_bind_key("M-]",next_brace)   
global_bind_key("C-M-b",IDM_SELECTTOBRACE)

select_quote_prev=function()
	local s=search_regexp_prev("[^\\\\]\\([\"']\\).*[^\\\\]+\\1",editor.SelectionStart)
	if s>=0 then set_sel(s+1,editor.SelectionEnd) end
	return true
end

select_quote_next=function()
	local s=search_regexp_next("[^\\\\]\\([\"']\\).*[^\\\\]+\\1",editor.SelectionEnd)
	if s>=0 then set_sel(s+1,editor.SelectionEnd) end
	return true
end

global_bind_key("M-`",select_quote_prev)
global_bind_key("M-'",select_quote_next)

capitalize_sentences=function()
	local pos=editor.CurrentPos
	local s,e,cur
	if editor.SelectionEmpty then
		s,e=0,editor.Length
	else
		s,e=editor.SelectionStart,editor.SelectionEnd
	end
	s=search_regexp_next("[a-z]",s)
	while s>=0 and s<e do
		cur=editor.SelectionEnd
		set_sel(cur-1,cur)
		replace_sel(string.upper(get_sel_text()))
		s=search_regexp_next("[;\\.]\\s+[a-z]",cur)
	end
	editor:SetEmptySelection(pos)
end
global_bind_key("M-c M-c",capitalize_sentences)

next_snippet=function()
	search_regexp_next("@[^@]*@",editor.SelectionEnd)
	return true
end
global_bind_key("M-s",next_snippet)

