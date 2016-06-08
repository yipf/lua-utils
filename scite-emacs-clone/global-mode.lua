require "global"

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- basic functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

global_bind_key("C-s",IDM_INCSEARCH)
global_bind_key("C-r",IDM_REPLACE)

global_bind_key("C-x k",IDM_CLOSE)
global_bind_key("C-x 0",IDM_CLOSE)
global_bind_key("C-x h",IDM_SELECTALL)

global_bind_key("C-x C-s",IDM_SAVE,"Save current buffer!")
global_bind_key("C-x C-w",IDM_SAVEAS)
global_bind_key("C-x C-o",IDM_OPENSELECTED)
global_bind_key("C-x C-n",IDM_NEW)
global_bind_key("C-x C-f",IDM_OPEN)
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

global_bind_key("M-d","DelWordRight")
global_bind_key("M-BACKSPACE","DelWordLeft")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- smart tab
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local a,z,A,Z=byte("a"),byte("z"),byte("A"),byte("Z")
local is_char=function(ch) return ch>=a and ch<=z or ch>=A and ch<=Z end

smart_tab=function()
	if buffer.session then return buffer.session() end
	if editor.SelectionEmpty then
		local pos=editor.CurrentPos
		if pos==line2position(position2line(pos)) then --if at head of current line
			expand_fold()
			return true
		elseif pos>0 and is_char(editor.CharAt[pos-1]) then -- if current character is word
			expand_word()
			return true
		end
	end
	editor:Tab()
	return true
end
global_bind_key("TAB",smart_tab)

reset_all=function()
	clear_anchor()
	buffer.session=nil
	buffer.top=0
	editor:Cancel()
	reset_pos()
	message("Reset!")
	return true
end
global_bind_key("C-g",reset_all)

smart_enter=function()
	local e=editor.CurrentPos
	local s=line2position(position2line(e))
	local text=editor:textrange(s,e)
	local prefix,id,subfix=string.match(text,"^(%s*%p*)(%w*)(%p+%s+).-$")
	if id then
		if id=="" then
			editor:AddText("\n"..prefix..id..subfix)
			return true
		else
			local num=tonumber(id)
			if num then 
				id=tostring(num+1)
			else
				num=string.byte(id)
				id=string.char(num+1)
			end
			editor:AddText("\n"..prefix..id..subfix)
		end
	else
		editor:NewLine()
	end
	return true
end
global_bind_key("M-ENTER",smart_enter)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- mark & selection & navigation
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

global_bind_key("C-@",set_anchor)

global_bind_key("M-<",navigation_functions"DocumentStart")
global_bind_key("M->",navigation_functions"DocumentEnd")

global_bind_key("C-a",navigation_functions"Home")
global_bind_key("C-e",navigation_functions"LineEnd")
global_bind_key("C-p",navigation_functions"LineUp")
global_bind_key("C-n",navigation_functions"LineDown")
global_bind_key("C-f",navigation_functions"CharRight")
global_bind_key("C-b",navigation_functions"CharLeft")

global_bind_key("C-[",navigation_functions"ParaUp")
global_bind_key("C-]",navigation_functions"ParaDown")
global_bind_key("M-b",navigation_functions"WordLeft")
global_bind_key("M-f",navigation_functions"WordRight")

sentence_start=function()
	if search_prev("[\\.\\;\\!\\?\\s]+\\s+\\w",editor.CurrentPos)>=0 then
		reset_pos(editor:PositionBefore(editor.SelectionEnd))
	end
	return true
end
sentence_end=function()
	if search_next("[\\.\\;\\!\\?\\s]+\\s+\\w",editor.CurrentPos)>=0 then
		reset_pos(editor:PositionBefore(editor.SelectionEnd))
	end
	return true
end
global_bind_key("M-a",navigation_functions(sentence_start))
global_bind_key("M-e",navigation_functions(sentence_end))

local parent_line=function(line)
	local l=editor.FoldParent[line]
	return l>=0 and l
end

local last_child=function(line)
	local l=editor:GetLastChild(line, -1)
	print(l)
	return l>=0 and l
end

local get_folder_range=function(line)
	local E=editor.LineCount-1
	local S=parent_line(line)
	if S then E=last_child(S) else S=0 end
	return S,E
end

local find_eq_header=function(level,s,e,d)
	local ll,is_header
	for i=s,e,d or 1 do
		ll,is_header=get_line_folder_level(i)
		if is_header and ll==level then return i end
	end
end

next_brother=function()
	local line=position2line(editor.CurrentPos)
	local level,is_header=get_line_folder_level(line)
	if not is_header then return true end
    local S,E=get_folder_range(line)
	local i=find_eq_header(level,line+1,E,1)
	if i then reset_pos(line2position(i)); return true end
	i=find_eq_header(level,S,line-1,1)
	if i then reset_pos(line2position(i)); return true end
	return true
end

previous_brother=function()
	local line=position2line(editor.CurrentPos)
	local level,is_header=get_line_folder_level(line)
	if not is_header then return true end
    local S,E=get_folder_range(line)
	local i=find_eq_header(level,line-1,S,-1)
	if i then reset_pos(line2position(i)); return true end
	i=find_eq_header(level,E,line+1,-1)
	if i then reset_pos(line2position(i)); return true end
	return true
end

parent_header=function()
	local line=position2line(editor.CurrentPos)
	line=parent_line(line)
	if line then reset_pos(line2position(line)) end
	return true
end

first_sub_header=function()
	local line=position2line(editor.CurrentPos)
	local level,is_header=get_line_folder_level(line)
	if not is_header then return true end
	local e=last_child(line)
	if not e then return true end
	for i=line+1,e do
		level,is_header=get_line_folder_level(i)
		if is_header then
			reset_pos(line2position(i))
			return true
		end
	end
	return true
end

global_bind_key("M-n",navigation_functions(next_brother))
global_bind_key("M-p",navigation_functions(previous_brother))
global_bind_key("M-u",navigation_functions(parent_header))
global_bind_key("M-s",navigation_functions(first_sub_header))

select_folder=function()
	local line=position2line(editor.CurrentPos)
	local level,is_header=get_line_folder_level(line)
	local S,E
	if is_header then
		S,E=line,last_child(line)
	else 
		S,E=get_folder_range(line)
	end
	set_sel(line2position(S),line2position(E+1))
	return true
end
global_bind_key("C-M-f",select_folder)

kill_sentence_to_end=function()
	local s=editor.CurrentPos
	if s<e then
		set_sel(s,editor.SelectionEnd)
		replace_sel("")
	end
	return true
end

kill_sentence_to_head=function()
	local e=editor.CurrentPos
	if e<1 then return true end
	local s=search_prev("[;\\.]\\s+",e-1)
	if s>0 and s<e then
		set_sel(editor.SelectionEnd,e)
		replace_sel("")
	end
	return true
end

global_bind_key("M-k",kill_sentence_to_end)   
global_bind_key("M-BACKSPACE",kill_sentence_to_head)   

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- interactive functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

do_string=function()
	set_sel(get_anchor(),editor.CurrentPos)
	replace_sel(eval_lua(get_sel()))
	return true
end
global_bind_key("M-x",intactive_functions(do_string))

local LS_FMT="ls -d -p %q*"
expand_path=function()
	local s,e=get_anchor(),editor.CurrentPos
	local path= s==e and "./" or editor:textrange(s,e)
	path=eval_cmd(format(LS_FMT,path))
	pop_list(e-s,path,"\n")
	return true
end
global_bind_key("M-/",intactive_functions(expand_path))

sel_paragraph=function()
	editor:ParaDown()
	editor:ParaUpExtend()
	return true
end
global_bind_key("M-h",sel_paragraph)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- writing tools: spell-checker, captitalizer, dictionry, ...
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
	word=get_sel()
	local candidate=get_candidate(word)
	if candidate then
		pop_list(string.len(word),candidate,"\n")
	else
		message("%q is right!",word)
	end
	return true
end
global_bind_key("M-$",check_word) 

next_error_word=function()
	local s,word,candidate
	repeat
		s=search_next("\\w+",editor.SelectionEnd)
		if s<0 then return true end -- no word any more
		word=get_sel()
		candidate=get_candidate(word)
	until candidate
	pop_list(string.len(word),candidate,"\n")
	return true
end
global_bind_key("M-!",next_error_word) 

show_dict=function()
	if editor.SelectionEmpty then sel_word(editor.CurrentPos) end
	local word=get_sel()
	message(eval_cmd(string.format("sdcv -n %s",word)))
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

prev_brace=function()
	local e=search_prev("[(\\[{]")
	if e>=0 then editor:SetEmptySelection(e) end
	return true
end

next_brace=function()
	local e=search_next("[)}\\]]")
	if e>=0 then editor:SetEmptySelection(e) end
	return true
end

global_bind_key("M-[",prev_brace)   
global_bind_key("M-]",next_brace)   
global_bind_key("C-M-b",IDM_SELECTTOBRACE)

select_quote_prev=function()
	local s=search_prev("[^\\\\]\\([\"']\\).*[^\\\\]+\\1",editor.SelectionStart)
	if s>=0 then set_sel(s+1,editor.SelectionEnd) end
	return true
end

select_quote_next=function()
	local s=search_next("[^\\\\]\\([\"']\\).*[^\\\\]+\\1",editor.SelectionEnd)
	if s>=0 then set_sel(s+1,editor.SelectionEnd) end
	return true
end

global_bind_key("M-`",select_quote_prev)
global_bind_key("M-'",select_quote_next)

capitalize_word=function()
	sel_word()
	local str=get_sel()
	str=string.gsub(str,"^[a-z]",string.upper)
	replace_sel(str)
	return true
end
global_bind_key("M-c",capitalize_word)

local status_word_char=function()
	local text= editor.SelectionEmpty and editor:GetText() or get_selx()
	local word_count,char_count=0,0
	for s,e in string.gmatch(" "..text,"%s+()[a-zA-Z%-]+()") do 
		word_count=word_count+1 
		char_count=char_count+e-s
	end
	message("Text include:%10d words %10d characters.",word_count,char_count)
	return true
end
global_bind_key("M-=",status_word_char) 

next_snippet=function()
	local s=search_next("@[^@]*@",editor.SelectionEnd)
	if s<0 then buffer.session=nil end -- if no matchs exit 
	return true
end
global_bind_key("M-@",next_snippet) 
