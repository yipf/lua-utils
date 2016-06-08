local env={}

env["SECTION0"]=[[
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>@CAPTION@</title>
</head>
<body>
<h0><center>@CAPTION@</center></h0>
@CONTENT@
</body>
</html>
]]

env["SECTION1"]="<h1>@ID@ @CAPTION@</h1>\n@CONTENT@"
env["SECTION2"]="<h2>@ID@ @CAPTION@</h2>\n@CONTENT@"
env["SECTION3"]="<h3>@ID@ @CAPTION@</h3>\n@CONTENT@"
env["SECTION4"]="<h4>@ID@ @CAPTION@</h4>\n@CONTENT@"

env["PARAGRAPH"]="<p>@CONTENT@</p>"

env["EXT"]="html"

local list2str
list2str=function(list,tp,level)
	local t={}
	for i,v in ipairs(list) do
		t[i]=string.gsub("<li>@CAPTION@</li>","@(.-)@",v)
	end
	return string.format("<%s>\n%s\n</%s>",tp,table.concat(t,"\n"),tp)
end

env["OL"]=function(list) 	return list2str(list,"ol") end
env["UL"]=function(list) 	return list2str(list,"ul") end




return env