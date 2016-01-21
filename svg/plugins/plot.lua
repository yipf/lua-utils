local id=function(x) return x,x end

local DEFS=""

local MARKER_FMT=[[<marker id=%q viewBox="0 0 20 20" refX="10" refY="10" markerUnits="strokeWidth" fill=%q markerWidth="8" markerHeight="8" >
			<path d=%q/></marker>]]

add_marker=function(key,color,path)
	DEFS=DEFS..(string.format(MARKER_FMT,key or "point",path,color or "none"))
	Set_canvas{DEFS=DEFS}
end

func2data=function(n,func)
	local data={}
	func=func or id
	for i=1,n do		data[i]={func(i)} 	end
	return data
end

require "svg-utils"

local number2string=function(num,fmt)
	return string.format(fmt or "%.2f",num)
end

local xmin,xmax,ymin,ymax=0,0,1,1
local _xy_01_=function(x,y)
	return (x-xmin)/(xmax-xmin),(y-ymin)/(ymax-ymin)
end

local top,left,width,height=100,100,800,600
local _01_xy_=function(x,y)
	return left+x*width,top+(1-y)*height
end

local offset_xlabel,offset_ylabel=-0.05,-0.03

local draw_coordinate=function(props)
	top,left,width,height=props.top or top,props.left or left,props.width or width,props.height or height
	Edge{{_01_xy_(0,0)},{_01_xy_(1,0)},STYLE={connection="->"}} --draw X
	Edge{{_01_xy_(0,0)},{_01_xy_(0,1)},STYLE={connection="->"}} --draw Y
	local nx,ny,GRID,x,y=props.XTics,props.YTics,props.GRID
	offset_xlabel,offset_ylabel=props.offset_xlabel or offset_xlabel,props.offset_ylabel or offset_ylabel
	if nx then
		x,y=_01_xy_(0,offset_xlabel)
		Node{lx=x,ly=y,SHAPE="label",LABEL=number2string(xmin)}
		for i=1,nx do	
			i=i/nx
			x,y=_01_xy_(i,offset_xlabel)
			Node{lx=x,ly=y,SHAPE="label",LABEL=number2string(xmin+i*(xmax-xmin))}
			if GRID then Edge{{_01_xy_(i,0)},{_01_xy_(i,1)},STYLE={connection="..."}} end
		end
	end
	if ny then
		x,y=_01_xy_(offset_ylabel,0)
		Node{lx=x,ly=y,SHAPE="label",LABEL=number2string(ymin),LSTYLE={align="end"}}
		for i=1,nx do	
			i=i/nx
			x,y=_01_xy_(offset_ylabel,i)
			Node{lx=x,ly=y,SHAPE="label",LABEL=number2string(ymin+i*(ymax-ymin)),LSTYLE={align="end"}}
			if GRID then Edge{{_01_xy_(0,i)},{_01_xy_(1,i)},STYLE={connection="..."}} end
		end
	end
end

local LINE_STYLES={}
define_style=function(id,line,marker)
	line,marker=line or "-",marker or ""
	LINE_STYLES[id]={{connection=marker..line..marker..line..marker},{connection=line..marker..line}}
end

plot2d=function(dataset,props)
	-- compute xmin,xmax,ymin,ymax
	local _xmax,_xmin,_ymax,_ymin
	for i,data in ipairs(dataset) do
		_xmin,_xmax=get_min_max(data,1,_xmin,_xmax)
		_ymin,_ymax=get_min_max(data,2,_ymin,_ymax)
	end
	xmin,xmax=props.xmin or _xmin or xmin, props.xmax or _xmax or xmax
	ymin,ymax=props.ymin or _ymin or ymin, props.ymax or _ymax or ymax
	-- draw coordinate system
	draw_coordinate(props or {})
	-- draw data
	x,y=_01_xy_(1.1,1) -- sample
	for i,data in ipairs(dataset) do
		local curve={}
		for i,v in ipairs(data) do
			curve[i]={_01_xy_(_xy_01_(unpack(v)))}
		end
		local style=LINE_STYLES[i]
		curve.STYLE=style and style[1]
		Edge(curve)
		-- draw sample
		y=y+20
		Node{lx=x,ly=y,SHAPE="label",LABEL=data.LABEL or "data_"..i,LSTYLE={align="end"}}
		Edge{{x+10,y},{x+30,y},{x+50,y},STYLE=style and style[2]}
	end
end


