package.path="/home/yipf/lua-utils/svg/?.lua;"..package.path

require "svg-utils"

local type=type
local push=table.insert 

local char2obj={["<"]="reverse-arrow",["o"]="point2d",[">"]="arrow"}

local match=string.match

local styles={
	dashed="stroke-dasharray:10,3",	
	dotted="stroke-dasharray:3,3",
	align="text-anchor:@position@",
	noborder="stroke-width:0",
	nofill="fill:none",
	
	connection=function(str)
		local s,m,e=string.match(str,"^([^%-%s%.]-)[%-%s%.]+([^%-%s%.]-)[%-%s%.]*([^%-%s%.]-)$")
		local ss=""
		s=match(s,"%S+");		if s~="" then ss=ss..string.format("marker-start:url(#%s);",char2obj[s] or s)		end
		e=match(e,"%S+");	if e~="" then ss=ss..string.format("marker-end:url(#%s);",char2obj[e] or e)		end
		m=match(m,"%S+");	if m~="" then ss=ss..string.format("marker-mid:url(#%s);",char2obj[m] or m) end
		if string.match(str,"%-%s+%-") then ss=ss.."stroke-dasharray:10,3;"
		elseif  string.match(str,"%.%.") then ss=ss.."stroke-dasharray:3,3;"  end
		return ss
	end,
	
	align_style=function(str)
		local s=string.match(str,"^%-*|()%-*$")
		return s==1 and "text-anchor:start" or s==string.len(str) and "text-anchor:end" or "text-anchor:middle"
	end,
	
	border_width="stroke-width:%s",
	border="stroke:%s",
	
	fill="fill:@color@",
	opacity="opacity:@opacity@",

}

local canvas={width=1600,height=1200,font_size=20}

local objects={}

Node=function(node)
	node.cx=node.cx or node[1] or 1; 	node.cy=node.cy or node[2] or node.cx
	node.rx= node.rx or 0; 	node.ry=node.ry or node.rx
	node.SHAPE=node.SHAPE or "rect"
	push(objects,node)
	return node
end

Edge=function(edge)
	edge.EDGE=true
	push(objects,edge)
	return edge
end

Group=function(group)
	group.GROUP=true
	push(objects,group)
	return group
end

local is_edge=function(obj) return obj.EDGE end

local gen_label=function(label,contents)
	label.lx,label.ly=label.lx or  label.cx ,label.ly or label.cy
	local dx,dy=label.dx or 0,label.dy or 0
	if label.LOFFSET then dx,dy=offset2xy(label.LOFFSET,dx,dy) end
	label.LSTYLE=style2str(label.LSTYLE or "stroke-width:1px;fill:black;text-anchor:middle;",styles)
	local lines={}
	for line in string.gmatch(label.LABEL,"(%C+)") do push(lines,line) end
	local mid=#lines/2
	label.dx=dx
	for i,line in ipairs(lines) do
		label.dy=(i-mid)*(canvas.font_size)+dy
		label.TEXT=line
		push(contents,eval(ENV["label"],label))
	end
	label.dy=dy
	return label
end

local gen_node=function(node,contents)
	node.STYLE=style2str(node.STYLE or "",styles)
	if node.SHAPE=="label" then return gen_label(node,contents) end
	push(contents,eval(ENV[node.SHAPE],node))
	if node.LABEL then 
		gen_label(node,contents)
	end
end

local gen_edge=function(edge,contents)
	edge.STYLE=style2str(edge.STYLE or "",styles)
	local shape,n,curve=edge.SHAPE,#edge
	if shape and n>1 then -- if it is a edge form point-to-point
		for i=1,n-1 do
			curve,edge.lx,edge.ly=pair2curve(edge[i],edge[i+1],edge.SHAPE)
			edge.PATH=curve2str(curve,edge.SMOOTH,edge.CLOSED)
			push(contents,eval(ENV["curve"],edge))
		end
	else	
		edge.PATH=curve2str(edge,edge.SMOOTH,edge.CLOSED)
		push(contents,eval(ENV["curve"],edge))
	end
	if edge.LABEL then 
		edge.lx,edge.ly=edge.lx or edge[1].cx,edge.ly or edge[1].cy
		gen_label(edge,contents)
	end
end

Export=function(filepath)
	local contents={}
	for i,obj in ipairs(objects) do
		if obj.EDGE then
			gen_edge(obj,contents)
		else
			if obj.GROUP then 
				local xmin,xmax,ymin,ymax=compute_border(obj)
				obj.cx,obj.cy=(xmin+xmax)/2,(ymin+ymax)/2
				obj.rx,obj.ry=(xmax-xmin)/2+(obj.xoffset or 0),(ymax-ymin)/2+(obj.yoffset or 0)
				obj.SHAPE=obj.SHAPE or "rect"
			end
			gen_node(obj,contents)
		end
	end
	canvas.BODY=table.concat(contents,"\n")
	-- export
	local str=eval(ENV["canvas"],canvas)
	if filepath then
		local name,ext=string.match(filepath,"^(.+)%.(.-)$")
		if not ext then name,ext=filepath,"svg" end
		local svg_file=name..".svg"
		print("Writing to",svg_file)
		local f=io.open(svg_file,"w"); 	f:write(str); 	f:close()
		if ext~="svg" then
			print("Writing to",filepath)
			print(io.popen(string.format("inkscape -e %q -z -D %q",filepath,svg_file)):read("*a"))
		end
	else
		print(str)
	end
end

Set_canvas=make_set_func(canvas)
Set_styles=make_set_func(styles)

local eq=function(a,b) return a==b end 

local include=function(edge,node)
	local id
	if not is_edge(edge) then return false end
	for i,v in ipairs(edge) do	if v==node then id=i; break; end end
	if not id then return false end
	table.remove(edge,i)
	return #edge<2
end

Remove=function(obj)
	if not obj then objects={} return end -- if obj is not given, remove all objects
	tag_elements(objects,eq,obj,"__REMOVED",true)
	if not is_edge(obj) then
		tag_elements(objects,include,obj,"__REMOVED",true)
	end
	remove_elements(objects,"__REMOVED",true)
end

ENV={
	-- basic shapes
	["curve"]=[[<path d="@PATH@" style="@STYLE or ''@"  />]],
	["rect"]=[[<rect x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry@" style="@STYLE or ''@" />]],
	["ellipse"]=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@" style="@STYLE or ''@" />]],
	["img"]=[[<image x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry@" xlink:href="@SRC@" filter="@filter@"  style="@STYLE or ''@"/>]],
	mulbox=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@"  STYLE="@STYLE or ''@"  /><path d="M @cx-0.707*rx@ @cy-0.707*ry@ L @cx+0.707*rx@ @cy+0.707*ry@ M @cx-0.707*rx@ @cy+0.707*ry@ L @cx+0.707*rx@ @cy-0.707*ry@" />]],
	addbox=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@"  STYLE="@STYLE or ''@" /><path d="M @cx-rx@ @cy@ L @cx+rx@ @cy@ M @cx@ @cy-ry@ L @cx@ @cy+ry@" />]],
	diamond=[[<path d="M @cx-rx@ @cy@ L @cx@ @cy-ry@ L @cx+rx@ @cy@ L @cx@ @cy+ry@ z"   style="@STYLE or ''@" />]],
	database=[[
	 <g style="@STYLE or ''@;fill:white;">
	 <ellipse cx="@cx@" cy="@cy+ry/2@" rx="@rx@" ry="@ry/2@"  />
	 <rect x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry/2@" style="stroke:none;" />
	 <ellipse cx="@cx@" cy="@cy-ry@" rx="@rx@" ry="@ry/2@"   />
	 <path d="M @cx-rx@ @cy-ry@ L @cx-rx@ @cy+ry/2@ M @cx+rx@ @cy-ry@ L @cx+rx@ @cy+ry/2@" />
	 </g>
	]],
	-- label elements
	["label"]=[[<text x="@lx@" y="@ly@" dx="@dx@" dy="@dy@" style="@LSTYLE or ''@">@TEXT@</text>]],
	-- marker
}

ENV.canvas=[[
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="@width@" height="@height@" font-size="@font_size@px" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="stroke: black; stroke-width: 2px; fill: none" >
<style> text{stroke:none; stroke-width:0px; fill:black;} </style>

 <defs>
		<marker id="arrow" viewBox="0 0 20 20" refX="20" refY="10" markerUnits="strokeWidth" fill="black" markerWidth="8" markerHeight="6" orient="auto">
			<path d="M 0 0 L 20 10 L 0 20 L 10 10 z"/>
		</marker>
		<marker id="reverse-arrow" viewBox="0 0 20 20" refX="0" refY="10" markerUnits="strokeWidth" fill="black" markerWidth="8" markerHeight="6" orient="auto">
			<path d="M 20 0 L 0 10 L 20 20 L 10 10 z"/>
		</marker>
		<marker id="point2d" viewBox="0 0 20 20" refX="10" refY="10" markerUnits="strokeWidth" fill="orange" markerWidth="6" markerHeight="6" orient="auto">
			<circle cx="10" cy="10" r="9" />
		</marker>
				<marker id="point2d-black" viewBox="0 0 20 20" refX="10" refY="10" markerUnits="strokeWidth" fill="black" markerWidth="6" markerHeight="6" orient="auto">
			<circle cx="10" cy="10" r="9" />
		</marker>
		<marker id="point2d-white" viewBox="0 0 20 20" refX="10" refY="10" markerUnits="strokeWidth" fill="white" markerWidth="6" markerHeight="6" orient="auto">
			<circle cx="10" cy="10" r="9" />
		</marker>
		<marker id="point2d-gray" viewBox="0 0 20 20" refX="10" refY="10" markerUnits="strokeWidth" fill="#888888" markerWidth="6" markerHeight="6" orient="auto">
			<circle cx="10" cy="10" r="9" />
		</marker>
		 <filter id='shadow' filterRes='50' x='0' y='0'>
			<feGaussianBlur stdDeviation='2 2'/>
			<feOffset dx='2' dy='2'/>
		</filter>
		<linearGradient x1='0%' x2='100%' id='linear0' y1='0%' y2='100%'>
			<stop offset='0%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='100%' style='stop-color:rgb(220,220,220);stop-opacity:1'/>
		</linearGradient>
		<linearGradient x1='0%' x2='100%' id='multi0' y1='100%' y2='100%'>
			<stop offset='0%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='45%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='46%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='50%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='54%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='55%' style='stop-color:rgb(220,220,220);stop-opacity:1'/>
			<stop offset='100%' style='stop-color:rgb(220,220,220);stop-opacity:1'/>
		</linearGradient>
		<linearGradient x1='100%' x2='0%' id='multi1' y1='100%' y2='100%'>
			<stop offset='0%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='45%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='46%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='50%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='54%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='55%' style='stop-color:rgb(220,220,220);stop-opacity:1'/>
			<stop offset='100%' style='stop-color:rgb(220,220,220);stop-opacity:1'/>
		</linearGradient>
		<linearGradient x1='100%' x2='0%' id='multi2' y1='100%' y2='100%'>
			<stop offset='0%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='45%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='46%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='50%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='54%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='55%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='100%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
		</linearGradient>
		<radialGradient id="radial0" cx="30%" cy="30%" r="50%">
			<stop offset="0%" style="stop-color:rgb(255,255,255); stop-opacity:0" />
			<stop offset="100%" style="stop-color:rgb(0,0,255);stop-opacity:1" />
     </radialGradient>
	 @DEFS or ""@
     </defs>
@BODY@
</svg>
]]

local filepath=...
if filepath then
	dofile(filepath)
else
	print("Need valid file path!")
end
