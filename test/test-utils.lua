Eval=function(str)
	local f=loadstring("return "..str)
	print(str,"=",f())
end