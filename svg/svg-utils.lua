local type=type
local gsub=string.gsub
local push=table.insert 

local make_ref_func=function(obj)
	local setfenv,loadstring=setfenv,loadstring
	return function(str)
		local func=loadstring("return "..str)
		return setfenv(func,obj)()
	end
end

eval=function(key,value) 
	return type(key)=="function" and key(value) or type(key)=="string" and gsub(key,"@%s*(.-)%s*@",make_ref_func(value)) 
end

style2str=function(style,ref)
	if type(style)~="table" then return style end
	local t,st,tp={}
	local format,tostring=string.format,tostring
	for k,v in pairs(style) do 
		st=ref[k]
		tp=type(st)
		push(t,tp=="function" and st(v) or tp=="string" and string.gsub(st,"@.-@",v) or k..":"..v)	
	end
	return table.concat(t,";")
end

local match=string.match
local tonumber=tonumber
offset2xy=function(str,x,y)
	x,y=x or 0,y or 0
	local d=0
	d=match(str,"U(%d*)");	if d then d=tonumber(d) or 0; y=y-d end
	d=match(str,"D(%d*)");  if d then d=tonumber(d) or 0; y=y+d end
	d=match(str,"L(%d*)");	if d then d=tonumber(d) or 0; x=x-d end
	d=match(str,"R(%d*)");	if d then d=tonumber(d) or 0; x=x+d end
	return x,y
end

local sqrt,abs,atan2,tan,pi=math.sqrt,math.abs,math.atan2,math.tan,math.pi

local border_func={
	['rect']=function(x,y,cx,cy,rx,ry)
		local dx,dy=x-cx,y-cy
		local a1,a=atan2(dy,dx),atan2(ry,rx)  
		if a1>=a and a1<=pi-a then			x,y=ry*dx/dy,ry
		elseif a1>=a-pi and a1<=-a then			x,y=-ry*dx/dy,-ry
		elseif a1>=-a and a1<=a then			x,y=rx,rx*dy/dx
		else	x,y=-rx,-rx*dy/dx
		end
		return cx+x,cy+y
	end,
	['ellipse']=function(x,y,cx,cy,rx,ry)
		local dx,dy=x-cx,y-cy
		if cx==x then return cx,cy+(dy>=ry and ry or dy<=-ry and -ry or 0) end
		local t,aa,bb=(cy-y)/(cx-x),rx*rx,ry*ry
		dx=sqrt(aa*bb/(t*t*aa+bb))
		dy=abs(t*dx)
		return cx+(x>cx and dx or -dx),cy+(y>cy and dy or -dy)
	end
}

local get_border=function(n,x,y)
	return (border_func[n.SHAPE] or border_func["rect"])(x,y,n.cx,n.cy,n.rx,n.ry)
end

get_proper_mid=function(c1,r1,c2,r2)
	local c=(c1+c2)/2
	if c1>=c2 then
		if c>(c2+r1) and c<(c1-r1) then return c end
		return c1+r1+r2
	end
	return get_proper_mid(c2,r2,c1,r1)
end

pair2curve=function(from,to,shape)
	local curve,cx,cy,x,y={}
	local fx,fy,tx,ty=from.cx,from.cy,to.cx,to.cy
	shape=shape or "-"
	if shape=="L" and fx~=tx and fy~=ty  then
		cx,cy=fx,ty
		x,y=get_border(from,cx,cy);	curve[1]={x,y}
		curve[2]={cx,cy}
		x,y=get_border(to,cx,cy);	curve[3]={x,y}
	elseif shape=="7" and fy~=ty and fx~=tx then
		cx,cy=tx,fy
		x,y=get_border(from,cx,cy);	curve[1]={x,y}
		curve[2]={cx,cy}
		x,y=get_border(to,cx,cy);	curve[3]={x,y}
	elseif shape=="Z" then
		cx=get_proper_mid(fx,from.rx,tx,to.rx)
		cy=(fy+ty)/2
		x,y=get_border(from,cx,fy);	curve[1]={x,y}
		curve[2]={cx,fy}
		curve[3]={cx,ty}
		x,y=get_border(to,cx,ty);	curve[4]={x,y}
	elseif shape=="N" then
		cy=get_proper_mid(fy,from.ry,ty,to.ry)
		cx=(fx+tx)/2
		x,y=get_border(from,fx,cy);	curve[1]={x,y}
		curve[2]={fx,cy}
		curve[3]={tx,cy}
		x,y=get_border(to,tx,cy);	curve[4]={x,y}
	else -- connnect directly
		cx,cy=(fx+tx)/2,(fy+ty)/2
		x,y=get_border(from,tx,ty);	curve[1]={x,y}
		x,y=get_border(to,fx,fy);			curve[2]={x,y}
	end
	return curve,cx,cy
end

curve2str=function(curve,smooth,closed)
	local n=#curve
	local t,p={"M"}
	p=curve[1];	push(t,p[1]);	push(t,p[2])
	if smooth and n>3 and n%2==0 then
		push(t,"C")
		p=curve[2]; 	push(t,p[1]);	push(t,p[2])
		p=curve[3]; 	push(t,p[1]);	push(t,p[2])
		p=curve[4]; 	push(t,p[1]);	push(t,p[2])
		for i=5,n,2 do
			push(t,"S")
			p=curve[i]; 	push(t,p[1]);	push(t,p[2])
			p=curve[i+1]; 	push(t,p[1]);	push(t,p[2])
		end
	elseif smooth and n>2 then
		push(t,"Q")
		p=curve[2]; 	push(t,p[1]);	push(t,p[2])
		p=curve[3]; 	push(t,p[1]);	push(t,p[2])
		for i=4,n do
			push(t,"T")
			p=curve[i]; 	push(t,p[1]);	push(t,p[2])
		end
	else
		for i=2,n do
			push(t,"L")	p=curve[i]; 	push(t,p[1]);	push(t,p[2])
		end
	end
	return table.concat(t," ")..(closed and " Z" or "") 
end

tag_elements=function(arr,filter,obj,key,value)
	for i,v in ipairs(arr) do
		if filter(v,obj) then v[key]=value end
	end
end

remove_elements=function(arr,key,value)
	local insert,remove=table.insert,table.remove
	local ids={}
	for i,v in ipairs(v) do		
		if v[key]==value then insert(ids,i) end
	end
	for i,v in ipairs(ids) do remove(arr,v-i+1) end
	return arr
end

make_set_func=function(dst)
	return function(props)
		for k,v in pairs(props) do
			dst[k]=v
		end
	end
end

get_min_max=function(arr,key,min,max)
	min,max=min or math.huge,max or -math.huge
	for i,a in ipairs(arr) do
		a=a[key]
		if a<min then min=a 
		elseif a>max then max=a
		end
	end
	return min,max
end

compute_border=function(nodes)
	local xmin,xmax,ymin,ymax=math.huge,-math.huge,math.huge,-math.huge
	local max,min=math.max,math.min
	for i,v in ipairs(nodes) do
		xmin=min(xmin,v.cx-v.rx)
		xmax=max(xmax,v.cx+v.rx)
		ymin=min(ymin,v.cy-v.ry)
		ymax=max(ymax,v.cy+v.ry)
	end
	return xmin,xmax,ymin,ymax
end

copy_props=function(src,dst)
	dst=dst or {}
	for k,v in pairs(src) do
		if type(k)~="number" then dst[k]=v end
	end
	return dst
end