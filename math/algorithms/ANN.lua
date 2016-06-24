--------------------------------------------------------------------------------------------------------------------------------
-- Framework of ANN
--------------------------------------------------------------------------------------------------------------------------------

local init_vector=function(n,value)
	value=value or 0
	local vector={}
	for i=1,n do
		vector[i]=value
	end
	return vector
end

local init_weight_matrix=function(function_N,weight_N)
	local matrix={}
	for i=1,function_N do
		matrix=init_vector(weight_N,1/weight_N)
	end
	return matrix
end

local init_values=function(input_N,layers)
	local values={}
	values[1]=init_vector(#input_vector,0)
	for i,v in ipairs(layers) do
		values[i]=init_vector(#layer,0)
	end
	return values
end

local init_weights=function(values)
	local weights={}
	for i=1,#values-1 do
		weights[i]=init_weight_matrix(#values[i+1],#values[i])
	end
	return weights
end

local dot=function(v1,v2)
	local sum=0
	for i,v in ipairs(v1) do
		sum=sum+v*v2[i]
	end
	return sum
end

local do_layer=function(input_vector,weight_matrix,output_vector,layer)
	for i,v in ipairs(layer) do
		output_vector[i]=v(dot(input_vector,weight_matrix[i]))
	end
	return output_vector
end

local do_layers_forward=function(values,weights,layers)
	for i=1,#layers do
		values[i+1]=do_layer(values[i],weights[i],values[i+1],layers[i])
	end
	return values,weights
end

local train=function(input,label,layers,update_func,test_func,values,weights)
	values=values or init_values(input,layers)
	weights=weights or init_weights(values)
	repeat
		values,weights=do_layers_forward(values,weights,layers)
		update_func(values,weights,input,label)
	until test_func(values)
	return value,weights
end

ANN=function(inputs,labels,layers,update_func,test_func)
	local values=init_values(#inputs[1],layers)
	local weights=init_weights(values)
	for i,input in ipairs(inputs) do
		values,weights=train(input,labels[i],layers,update_func,test_func,values,weights)
	end
	return values,weights,layers
end

--------------------------------------------------------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------------------------------------------------------
