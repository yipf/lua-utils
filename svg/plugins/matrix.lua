
require "svg-utils"
local copy_props=copy_props

local props={rx=25,ry=25,dx=100,dy=100,STYLE="fill:none;",SHAPE="ellipse"}

Set_matrix=make_set_func(props)

Cell=function(label,shape,x,y,ref)
	shape,x,y=shape or props.SHAPE,x and x*props.dx or 0, y and y*props.dy or 0
	if ref then x=x+ref.cx; 	y=y+ref.cy end
	return Node{LABEL=label,SHAPE=shape, cx=x,cy=y,rx=props.rx,ry=props.ry}
end

