-- lexer for scite

local FOLDER_BASE,FOLDER_HEADER,NORMAL=SC_FOLDLEVELBASE,SC_FOLDLEVELHEADERFLAG+SC_FOLDLEVELBASE,SC_FOLDLEVELBASE+20
local BLOCK_BEGIN,BLOCK_END=FOLDER_HEADER+10,FOLDER_BASE+10
local PROPS_STYLE,BLOCK_STYLE,FILE_STYLE,NORMAL_STYLE=10,11,12,0

local FIRST_FOLDER_LEVEL=FOLDER_HEADER-1

local match,len,gmatch,sub=string.match,string.len,string.gmatch,string.sub

local inline_table={['$']=21,['!']=22,['*']=23,['#']=24,['`']=25}

local style_line=function(str,s,e,style)
	if s>1 then editor:SetStyling(s-1, style); str=sub(str,s,e); e=e-s+1; s=1; end
	for ss,p,ee in gmatch(str,"()([!#%*%$`])%2.-%2%2()") do
		editor:SetStyling(ss-s, style)
		editor:SetStyling(ee-ss, inline_table[p] or style)
		s=ee
	end
	if s<=e then editor:SetStyling(e-s+1, style) end
end

local SPECIAL_PAT="^@"

local lexer=function(line)
	local str=editor:GetLine(line)
	if not str then editor.FoldLevel[line]=NORMAL return end
	local n=len(str)
	if match(str,SPECIAL_PAT) then
		editor.FoldLevel[line]=FIRST_FOLDER_LEVEL
		editor:SetStyling(n,PROPS_STYLE)
	else
		editor.FoldLevel[line]=FOLDER_HEADER
		style_line(str,1,n,NORMAL_STYLE)
	end
end

return lexer;