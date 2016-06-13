local env={}

env["EXT"]="html"

env["SECTION0"]=[[
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>@CAPTION@</title>
<script type="text/x-mathjax-config">
  MathJax.Hub.Config({tex2jax: {inlineMath: [ ['$','$'], ['\\(','\\)'] ]}});
</script>
<script type="text/javascript" async
  src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_CHTML">
</script>
</head>
<body>
<h0><center>@CAPTION@</center></h0>
@CONTENT@
</body>
</html>
]]

env["SECTION1"]="<h1 id='@TYPE@:@ID@'>@ID@ @CAPTION@</h1>\n@CONTENT@"
env["SECTION2"]="<h2 id='@TYPE@:@ID@'>@ID@ @CAPTION@</h2>\n@CONTENT@"
env["SECTION3"]="<h3 id='@TYPE@:@ID@'>@ID@ @CAPTION@</h3>\n@CONTENT@"
env["SECTION4"]="<h4 id='@TYPE@:@ID@'>@ID@ @CAPTION@</h4>\n@CONTENT@"

env["PARAGRAPH"]="<p>@CONTENT@</p>"

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

local enclose_element=function(tag,content)
	return string.format("<%s>%s</%s>",tag,content,tag)
end

local cells2row=function(cells,tag)
	local t={}
	for i,cell in ipairs(cells) do		t[i]=enclose_element(tag,cell)	end
	return table.concat(t)
end

local table2body=function(tbl)
	local t={}
	t[1]=enclose_element("tr",cells2row(tbl[1],"th"))
	for i=2,#tbl  do
		t[i]=enclose_element("tr",cells2row(tbl[i],"td"))
	end
	return table.concat(t)
end

env["TABLE"]=function(tbl)
	local t={}
	for i,v in ipairs(tbl) do
		if v[1] then table.insert(t,v) end
	end
	tbl.CONTENT=table2body(t)
	return string.gsub("<p>@TYPE@.@ID@ @CAPTION@</p><table border='2px' id='@TYPE@:@ID@'>@CONTENT@</table>","@(.-)@",tbl)
end

env["toc-item"]="<p><a href='#@TYPE@:@ID@'>@ID@ @CAPTION@</a></p>"
env["toc-block"]="<h2>@CAPTION@</h2>@CONTENT@"
env["toc"]="<div  style='border-width:2px;  border-color:Blue; border-style:solid; width:25%;'><h1>@CAPTION@</h1>@CONTENT@</div>"

-- styles for  inline elements

env["em"]="<strong>@CONTENT@</strong>"
env["eq"]="$@CONTENT@$"
env["quote"]="\"@CONTENT@\""
env["ref"]="<a href='#@ID@'>@CAPTION@</a>"
env["img"]=[[<img src="@URL@" alt="@DESC@" />]]
env["http"]=[[<a href='http:@URL@'>@CAPTION@</a>]]

env["EQ"]="\\[@CONTENT@\\]"
env["FIGURE"]=[[<p>@TYPE@.@ID@ @CAPTION@</p><p><img src="@CONTENT@" alt="@CAPTION@" id='@TYPE@:@ID@' /></p>]]

return env