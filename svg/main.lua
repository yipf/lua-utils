package.path="/home/yipf/lua-utils/svg/?.lua;"..package.path

require "svg-utils"

local type=type
local push=table.insert 

default_node_style=""
default_curve_style=""
default_label_style="stroke-width:1px;fill:black;text-anchor:middle;"

make_canvas=function(w,h,font_size)
	local nodes,edges,labels={},{},{}
	w,h,font_size,dw,dh=w or 800,h or 600,font_size or 20
	local create_node=function(node)
		node[1]=node[1] or 1; 	node[2]=node[2] or node[1]
		node.rx= node.rx or 0; 	node.ry=node.ry or node.rx
		node.SHAPE=node.SHAPE or "rect"
		push(nodes,node)
		if node.LABEL then push(labels,node) end
		return node
	end
	local create_edge=function(edge)
		push(edges,edge)
		if edge.LABEL then push(labels,edge) end
		return edge
	end
	export=function(filepath)
		local canvas={w=w,h=h,font_size=font_size}
		local contents={}
		for i,node in ipairs(nodes) do
			node.cx,node.cy=node[1],node[2]
			node.STYLE=style2str(node.STYLE or default_node_style,styles)
			if node.LABEL then node.lx,node.ly=node.cx,node.cy end -- perparing generating label
			push(contents,eval(ENV[node.SHAPE],node))
		end
		for i,edge in ipairs(edges) do
			edge.STYLE=style2str(edge.STYLE or default_edge_style,styles)
			local curve=edge
			if edge.SHAPE then
				curve,edge.lx,edge.ly=pair2curve(edge[1],edge[2],edge.SHAPE)
			end
			edge.LINE=curve2str(curve,edge.SMOOTH,edge.CLOSED)
			push(contents,eval(ENV["curve"],edge))
		end
		for i,label in ipairs(labels) do
			local lx,ly=label.lx,label.ly
			if label.LOFFSET then lx,ly=offset2xy(label.LOFFSET,lx,ly) end
			label.LSTYLE=style2str(label.LSTYLE or default_label_style,styles)
			local lines={}
			for line in string.gmatch(label.LABEL,"(%C+)") do push(lines,line) end
			local vbase,mid=label.ly,#lines/2
			for i,line in ipairs(lines) do
				label.ly=vbase+(i-mid)*(font_size)
				label.TEXT=line
				push(contents,eval(ENV["label"],label))
			end
		end
		canvas.VALUE=table.concat(contents,"\n")
		-- export
		local str=eval(ENV["canvas"],canvas)
		if filepath then
			local f=io.open(filepath..".svg","w")
			f:write(str)
			f:close()
		else
			print(str)
		end
	end
	return create_node,create_edge,export
end

styles={
	dashed="stroke-dasharray:10,3",	
	dotted="stroke-dasharray:3,3",
	align="text-anchor:%s",
	noborder="stroke-width:0",
	nofill="fill:none",
	
	border_width="stroke-width:%s",
	border="stroke:%s",
	
	fill="fill:%s",
	opacity="opacity:%s",

}

ENV={
	-- basic shapes
	["curve"]=[[<path d="@LINE@" style="@STYLE@" />]],
	["rect"]=[[<rect x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry@" style="@STYLE@" />]],
	["ellipse"]=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@" style="@STYLE@" />]],
	-- label elements
	["label"]=[[<text x="@lx@" y="@ly@" style="@LSTYLE@">@TEXT@</text>]],
}

ENV.canvas=[[
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="@w@" height="@h@" font-size="@font_size@px" version="1.1" xmlns="http://www.w3.org/2000/svg" style="stroke: black; stroke-width: 3px; fill: none" >
<style> text{stroke: black; stroke-width: 1px; fill: black;} </style>
@VALUE@
</svg>
]]