local props={rx=25,ry=25,DX=100,DY=100,STYLE="fill:none;",SHAPE="rect",ESHAPE="-",SMOOTH=false}

Set_tree=make_set_func(props)

local push=table.insert

local labels2tr
labels2tr=function(labels,nodes,level) -- prepare tree nodes and store them in `nodes'
	level=level or 1
	nodes=nodes or {}
	local label,child=unpack(labels)
	local tr=Node{LABEL=label or "node",rx=props.rx,ry=props.ry,SHAPE=props.SHAPE,LEVEL=level or 1}
	push(nodes,tr)
	local sum,n=1
	if child then
		sum=0
		for i,v in ipairs(child) do
			n=labels2tr(v,nodes,level+1)
			tr[i]=n
			Edge{tr,n,SHAPE=props.ESHAPE,SMOOTH=props.SMOOTH,STYLE=props.STYLE}
			sum=sum+n.SUM
		end
	end
	tr.SUM=sum
	return tr
end

local calculate_xy_LR
calculate_xy_LR=function(tr,dx,dy,x,y) -- map a tree to a matrix plane
	tr.cx,tr.cy=x+tr.LEVEL*dx,y+(tr.SUM+1)/2*dy
	local sum
	for i=1,#tr do
		sum= (i>1) and (sum+tr[i-1].SUM) or 0
		calculate_xy_LR(tr[i],dx,dy,x,y+sum*dy)
	end
	return tr
end

make_tree_LR=function(labels)  -- make a left-to-right tree 
	local nodes={}
	local tr=labels2tr(labels,nodes,1)
	return calculate_xy_LR(tr,props.DX,props.DY,0,0),nodes
end

make_tree_UD=function(labels)  -- make an up-to-down tree 
	local nodes={}
	local tr=labels2tr(labels,nodes,1)
	calculate_xy_LR(tr,props.DY,props.DX,0,0)
	for i,v in ipairs(nodes) do
		v[1],v[2]=v[2],v[1]
	end
	return tr,nodes
end

