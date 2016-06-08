require "plugins/matrix"

Set_flowchart=Set_matrix
Set_flowchart{dx=150,dy=100,rx=50,ry=20}

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

make_flowchart_unit=function(label,shape,pos,ref)
	local x,y=offset2xy(pos)
	return Cell(label,shape or "rect",x,y,ref)
end

make_flowchart_units=function(t)
	local pos,ref,shape,offset=t.pos or "D1",t.ref,t.shape or "rect",t.offset or "D1"
	local n=#t
	if n<1  then return end
	local x,y=offset2xy(pos)
	local units={Cell(t[1],shape,x,y,ref)}
	x,y=offset2xy(offset)
	for i=2,n do
		units[i]=Cell(t[i],shape,x,y,units[i-1])
	end
	return units
end

link_units=function(units,arrow_type,link_shape)
	units.STYLE={connection=arrow_type}
	units.SHAPE=link_shape
	Edge(units)
end