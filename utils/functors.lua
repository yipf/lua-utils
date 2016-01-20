
make_unique=function(value2key,KV,VK)
	KV,VK=KV or {},VK or {}
	return function(element)
		local key=VK[element]
		if key then return key,element end
		key=value2key(element)
		local value= KV[key]
		if value then return key,value end
		value=element
		KV[key]=value
		VK[value]=key
		return key, value
	end
end