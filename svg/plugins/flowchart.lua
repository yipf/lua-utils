require "plugins/matrix"

Set_matrix{dx=150,dy=100,rx=50,ry=20}

require "svg-utils"
local offset2xy=offset2xy

process=function(label,pos_str,ref)
	local x,y=offset2xy(pos_str)
	return Cell(label,"rect",x,y,ref)
end

condition=function(label,pos_str,ref)
	local x,y=offset2xy(pos_str)
	return Cell(label,"diamond",x,y,ref)
end

state=function(label,pos_str,ref)
	local x,y=offset2xy(pos_str)
	return Cell(label,"ellipse",x,y,ref)
end
