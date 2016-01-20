local id=function(x) return x,x end

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

plot2d=function(data,props)
	local xy_pairs,xy={}
	local x,y,w,h=props.x or 0, props.y or 0, props.w or 800, props.h or 600
	local xmin,xmax=get_min_max(data,1)
	xmin,xmax=props.xmin or xmin, props.xmax or xmax
	local ymin,ymax=get_min_max(data,2)
	ymin,ymax=props.ymin or ymin, props.ymax or ymax
	local wx,hy=xmax-xmin,ymax-ymin
	for i,v in ipairs(data) do
		xy_pairs[i]={x+(v[1]-xmin)/wx*w,y+(ymax-v[2])/hy*h}
	end
	local nx=props.X
	if nx then
		Edge{{x,y+h},{x+w,y+h},STYLE={connection="->"}}
		for i=1,nx+1 do
			i=(i-1)/nx
			Node{lx=x+i*w,ly=y+h+30,LABEL=number2string(xmin+i*wx),SHAPE="label"}
		end
	end
	local ny=props.Y
	if ny then
		Edge{{x,y+h},{x,y},STYLE={connection="->"}}
		for i=1,ny+1 do
			i=(i-1)/ny
			Node{lx=x-20,ly=y+i*h,LABEL=number2string(ymax-i*hy),LOFFSET="L20",LSTYLE={align="end"},SHAPE="label"}
		end
	end
	if props.GRID then
		if nx then 
			for i=1,ny do
				i=i/ny
				Edge{{x+i*w,y+h},{x+i*w,y},STYLE={connection="..."}}
			end
		end
		if ny then
			for i=0,ny-1 do
				i=i/ny
				Edge{{x,y+i*h},{x+w,y+i*h},STYLE={connection="..."}}
			end
		end
	end
	local line=props.line
	if line then
		xy_pairs.STYLE=line
		Edge(xy_pairs)
	end
	local node=props.node
	if node then
		for i,v in ipairs(xy_pairs) do
			Node(node(v))
		end
	end
end

