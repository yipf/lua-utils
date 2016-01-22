local id=function(x) return x,x end

local DEFS=""

local MARKER_FMT=[[<marker id=%q viewBox="0 0 20 20" refX="10" refY="10" markerUnits="strokeWidth" fill=%q markerWidth="8" markerHeight="8" >
			<path d=%q/></marker>]]

Add_marker=function(key,color,path)
	DEFS=DEFS..(string.format(MARKER_FMT,key or "point",color or "none",path))
	Set_canvas{DEFS=DEFS}
end

func2data=function(n,func)
	local data={}
	func=func or id
	for i=1,n do		data[i]={func(i)} 	end
	return data
end

require "svg-utils"

Add_marker("triangle","blue","M 10 5 L 5 15 L 15 15 Z")
Add_marker("cross","none","M 10 0 L 10 20 M 0 10 L 20 10 ")
Add_marker("square","red","M 5 5 L 5 15 L 15 15 L 15 5 Z")
Add_marker("diamond","red","M 5 5 L 5 15 L 15 15 L 15 5 Z")
Add_marker("circle","green","M 20 10 A 5 5 0 0 0 20 10 Z ") --(rx ry x-axis-rotation large-arc-flag sweep-flag x y)+


local draw_label=function(text,x,y,align)
	return Node{SHAPE="label",LABEL=text,LSTYLE={align=align},lx=x,ly=y}
end

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

local huge=math.huge
local get_min=function(a,b,c)
	a,b,c=a or huge,b or huge,c or huge
	a= a>b and b or a
	a= a>c and c or a
	return a
end

local get_max=function(a,b,c)
	a,b,c=a or -huge,b or -huge,c or -huge
	a= a>b and a or b
	a= a>c and a or c
	return a
end

local draw_coordinate=function(props)
	top,left,width,height=props.top or top,props.left or left,props.width or width,props.height or height
	local nx,ny,GRID=props.XTics ,props.YTics,props.GRID
	if props.SYN then
		local hw=(ymax-ymin)/(xmax-xmin)
		height=width*hw
		if nx then	
			ny=math.floor(nx*hw+0.5); 
			height=height*nx*hw/ny
		end
	end
	Edge{{_01_xy_(0,0)},{_01_xy_(1.05,0)},STYLE={connection="->"}} --draw X
	Edge{{_01_xy_(0,0)},{_01_xy_(0,1.05)},STYLE={connection="->"}} --draw Y
	local x,y=_01_xy_(1.05,0)
	draw_label(props.XLabel or "X",x+10,y,"start")
	local x,y=_01_xy_(0,1.05)
	draw_label(props.YLabel or "Y",x,y-20)
	offset_xlabel,offset_ylabel=props.offset_xlabel or offset_xlabel,props.offset_ylabel or offset_ylabel
	if nx then
		x,y=_01_xy_(0,offset_xlabel)
		Node{lx=x,ly=y,SHAPE="label",LABEL=number2string(xmin)}
		for i=1,nx do	
			i=i/nx
			x,y=_01_xy_(i,offset_xlabel)
			draw_label(number2string(xmin+i*(xmax-xmin)),x,y)
			if GRID then Edge{{_01_xy_(i,0)},{_01_xy_(i,1)},STYLE={connection="..."}} end
		end
	end
	if ny then
		x,y=_01_xy_(offset_ylabel,0)
		draw_label(number2string(ymin),x,y,"end")
		for i=1,ny do	
			i=i/ny
			x,y=_01_xy_(offset_ylabel,i)
			draw_label(number2string(ymin+i*(ymax-ymin)),x,y,"end")
			if GRID then Edge{{_01_xy_(0,i)},{_01_xy_(1,i)},STYLE={connection="..."}} end
		end
	end
end

make_line_point_style=function(line,marker)
	line,marker=line or "-",marker or ""
	return	{connection=marker..line..marker..line..marker},{connection=line..marker..line}
end

plot2d=function(dataset,props)
	-- compute xmin,xmax,ymin,ymax
	local _xmax,_xmin,_ymax,_ymin
	for i,data in ipairs(dataset) do
		_xmin,_xmax=get_min_max(data,1,_xmin,_xmax)
		_ymin,_ymax=get_min_max(data,2,_ymin,_ymax)
	end
	xmin,xmax=get_min(props.Xmin,_xmin,xmin), get_max(props.Xmax,_xmax,xmax)
	ymin,ymax=get_min(props.Ymin,_ymin,ymin), get_max(props.Ymax,_ymax,ymax)
	-- draw coordinate system
	props=props or {}
	draw_coordinate(props)
	-- draw data
	x,y=_01_xy_(1.1,1) -- sample
	local n=#dataset
	Node{cx=x,cy=y+(n+1)*10,rx=0.08*width,ry=(n+0.5)*10} -- sample frame
	for i,data in ipairs(dataset) do
		local tp=data.TYPE
		local drawer=tp and Drawers[tp] or Drawers["curve"]
		y=y+20
		drawer(data,i,n,x,y)
	end
end

Drawers={
	curve=function(data,i,n,x,y)
			local style=data.STYLE or ""
			-- draw curve
			local curve={STYLE=style}
			for i,v in ipairs(data) do
				curve[i]={_01_xy_(_xy_01_(unpack(v)))}
			end
			Edge(curve)
			-- draw sample
			draw_label(data.LABEL or "data_"..i,x,y,"end")
			Edge{{x+10,y},{x+30,y},{x+50,y},STYLE=data.SAMPLE_STYLE or style}
	end,
	bar=function(data,i,n,x,y)
		local style=data.STYLE or ""
		local bx,by,dx,dy=_01_xy_(0,0)
		bx=(2*i-1-n)*5
		for i,v in ipairs(data) do
			dx,dy=_01_xy_(_xy_01_(unpack(v)))
			Node{cx=dx+bx,rx=5,cy=(by+dy)/2,ry=(by-dy)/2,STYLE=style}
		end		
		-- draw sample
		draw_label(data.LABEL or "data_"..i,x,y,"end")
		Node{cx=x+30,cy=y,rx=4,ry=8,STYLE=data.SAMPLE_STYLE or style,SHAPE="rect"}
	end,
	block=function(data,i,n,sx,sy)
		local curve={}
		for i,v in ipairs(data) do
			curve[i]={_01_xy_(_xy_01_(unpack(v)))}
		end
		local _,h=_01_xy_(0,0)
		local sx,ex=curve[1][1],curve[#data][1]
		table.insert(curve,1,{sx,h})
		table.insert(curve,{ex,h})
		local style=data.STYLE or ""
		Node{SHAPE="curve",PATH=curve2str(curve,false,true),STYLE=style}
		-- draw sample
		draw_label(data.LABEL or "data_"..i,x,y,"end")
		Node{cx=x+30,cy=y,rx=8,ry=8,STYLE=data.SAMPLE_STYLE or style,SHAPE="rect"}
	end,
}
