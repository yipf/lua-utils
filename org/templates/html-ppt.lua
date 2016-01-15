local PROP_PAT="@%s*(.-)%s*@"

local TOC_ITEM_PAT="<li><a href='#@TYPE@:@ID@'>@ID@ @CAPTION@</a> </li>"
local make_contents=function(tocs)
	local toc=tocs.SEC
	local t={"<ul>"}
	local push,gsub=table.insert,string.gsub
	for i,v in ipairs(toc) do
		if v.LEVEL<2 then
			push(t,(gsub(TOC_ITEM_PAT,"@%s*(.-)%s*@",v)))
		end
	end
	push(t,"</ul>")
	return table.concat(t)
end


local table_row=function(row,i) 
	return i==1 and ("<tr><th>"..table.concat(row,"</th><th>").."</th></tr>") or ("<tr><td>"..table.concat(row,"</td><td>").."</td></tr>")
end
local TABLE="<table id='@TYPE@:@ID@'><caption>@TYPE@.@ID@ @CAPTION@</caption>@VALUE@</table>"

local table_function=function(tbl)
	local pat=tbl.OPT or "[^|]+"
	local t,r={}
	local gmatch,push=string.gmatch,table.insert
	for l in gmatch(tbl.VALUE.."\n","(.-)\n") do
		r={}
		for cell in gmatch(l,pat) do
			push(r,cell)
		end
		push(t,r)
	end
	for i,v in ipairs(t) do
		t[i]=table_row(v,i) 
	end
	tbl.VALUE=table.concat(t,"\n")
	return (gsub(TABLE,PROP_PAT,tbl))
end

return {
	EXT='html',


	BLOCK="\n<@TYPE@ id='@TYPE@:@ID@'>\n@VALUE@\n<@TYPE@>",
	
	-- refs
	
	['cite_element']="<a href='#@TYPE@:@ID@'>@ID@</a>",
	
	REF_FMTS={
		['ARTICLE']=[[<li id='@TYPE@:@ID@'>@AUTHOR@, "@TITLE@", @JOURNAL@, vol. @VOLUME@, no. @NUMBER@, pp.@PAGES@, @YEAR@</li>]],
		['CONFERENCE']=[[<li id='@TYPE@:@ID@'>@AUTHOR@, "@TITLE@", @BOOKTITLE@, pp.@PAGES@, @YEAR@</li>]],
		['INPROCEEDINGS']=[[<li id='@TYPE@:@ID@'>@AUTHOR@, "@TITLE@", @BOOKTITLE@, pp.@PAGES@, @YEAR@</li>]],
	},
	['REFERENCES']="<h1>References</h1>\n<ol id='@NAME@'>@VALUE@<ol>",
	
	['TABLE_ROW']=function(row,i) 
		return i==1 and ("<tr><th>"..table.concat(row,"</th><th>").."</th></tr>") or ("<tr><td>"..table.concat(row,"</td><td>").."</td></tr>")
	end,
	['TABLE_MAIN']="<table id='@TYPE@:@ID@'><caption>@TYPE@.@ID@ @CAPTION@</caption>@VALUE@</table>",
	
	
	
	
	P="\n<p>@VALUE@</p>",
	
	['ref']="<a href='#@TYPE@:@ID@'>@ID@</a>",
	['em']="<strong><em>@1@</em></strong>",
	-- urls
	['http']="<a href='http:@1@'>@2@</a>",
	['https']="<a href='https:@1@'>@2@</a>",
	
	
	['quote']=[["@0@"]],
	
	['CODE']="<div id='@TYPE@:@ID@'><p>@TYPE@.@ID@ @CAPTION@</p>\n<textarea rows=10 cols=100>@VALUE@</textarea>\n</div>",
	
	['eq']=[[\(@0@\)]],
	
	['EQ']="<p id='@TYPE@:@ID@' class='eq'><span class='eq_label'>(@ID@)</span> \\[@VALUE@\\]  </p>",
	
	[0]=[[
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
  <meta name="viewport" content="width=1024, user-scalable=no">

  <title>@CAPTION@-@AUTHOR@-@DATE@</title>

  <!-- Required stylesheet -->
  <link rel="stylesheet" media="screen" href="deck.js/core/deck.core.css">

  <!-- Extension CSS files go here. Remove or add as needed. -->
  <link rel="stylesheet" media="screen" href="deck.js/extensions/goto/deck.goto.css">
  <link rel="stylesheet" media="screen" href="deck.js/extensions/menu/deck.menu.css">
  <link rel="stylesheet" media="screen" href="deck.js/extensions/navigation/deck.navigation.css">
  <link rel="stylesheet" media="screen" href="deck.js/extensions/status/deck.status.css">
  <link rel="stylesheet" media="screen" href="deck.js/extensions/scale/deck.scale.css">

  <!-- Style theme. More available in /themes/style/ or create your own. -->
  <link rel="stylesheet" media="screen" href="deck.js/themes/style/web-2.0.css">

  <!-- Transition theme. More available in /themes/transition/ or create your own. -->
  <link rel="stylesheet" media="screen" href="deck.js/themes/transition/horizontal-slide.css">

  <!-- Basic black and white print styles -->
  <link rel="stylesheet" media="print" href="deck.js/core/print.css">

  <!-- Required Modernizr file -->
  <script src="deck.js/modernizr.custom.js"></script>
</head>
<body>
  <div class="deck-container">

    <!-- Begin slides. Just make elements with a class of slide. -->

	<section class="slide">
      <h1>@CAPTION@ </h1>
    </section>
	
	@VALUE@
	
    <section class="slide">
      <h1>Thanks</h1>
    </section>

    <!-- End slides. -->

    <!-- Begin extension snippets. Add or remove as needed. -->

    <!-- deck.navigation snippet -->
    <div aria-role="navigation">
      <a href="#" class="deck-prev-link" title="Previous">&#8592;</a>
      <a href="#" class="deck-next-link" title="Next">&#8594;</a>
    </div>

    <!-- deck.status snippet -->
    <p class="deck-status" aria-role="status">
      <span class="deck-status-current"></span>
      /
      <span class="deck-status-total"></span>
    </p>

    <!-- deck.goto snippet -->
    <form action="." method="get" class="goto-form">
      <label for="goto-slide">Go to slide:</label>
      <input type="text" name="slidenum" id="goto-slide" list="goto-datalist">
      <datalist id="goto-datalist"></datalist>
      <input type="submit" value="Go">
    </form>

    <!-- End extension snippets. -->
  </div>

<!-- Required JS files. -->
<script src="deck.js/jquery.min.js"></script>
<script src="deck.js/core/deck.core.js"></script>

<!-- Extension JS files. Add or remove as needed. -->
<script src="deck.js/extensions/menu/deck.menu.js"></script>
<script src="deck.js/extensions/goto/deck.goto.js"></script>
<script src="deck.js/extensions/status/deck.status.js"></script>
<script src="deck.js/extensions/navigation/deck.navigation.js"></script>
<script src="deck.js/extensions/scale/deck.scale.js"></script>

<!-- Initialize the deck. You can put this in an external file if desired. -->
<script>
  $(function() {
    $.deck('.slide');
  });
</script>
</body>
</html>
]],
	
	[1]="\n<section class='slide' ><h1 id='@TYPE@:@ID@'>@ID@ @CAPTION@</h1></section>@VALUE@",
	[2]="\n<section class='slide' ><h2 id='@TYPE@:@ID@'>@ID@ @CAPTION@</h2>@VALUE@</section>",
--~ 	[3]="\n<section class='slide' ><h2 id='@TYPE@:@ID@'>@ID@ @CAPTION@</h2>@VALUE@</section>",
--~ 	[4]="\n<section class='slide' ><h2 id='@TYPE@:@ID@'>@ID@ @CAPTION@</h2>@VALUE@</section>",

	
	---   blocks
	TOC=toc_function,
	
	TABLE=table_function,
	
	['CODE']="<div id='@TYPE@:@ID@'><p>@TYPE@.@ID@ @CAPTION@</p>\n<textarea rows=10 cols=100>@VALUE@</textarea>\n</div>",
	
	['EQ']="<p id='@TYPE@:@ID@' class='eq'><span class='eq_label'>(@ID@)</span> \\[@VALUE@\\]  </p>",
	
	['FIG']=[[<div id='@TYPE@:@ID@'><center><img @OPT@ src='@VALUE@'/></center><center>Figure.@ID@ @CAPTION@</center><div>]],
	
	
	-- inblocks
	
	OL="<ol>@VALUE@</ol>",
	UL="<ul>@VALUE@</ul>",
	LI="<li>@VALUE@</li>",
	-- toc items
	make_contents=make_contents,
	
	-- inline elements
	['$']=[[\(@0@\)]], -- inline eq
	['*']="<strong><em>@1@</em></strong>", -- em
	['`']=[["@0@"]], -- quote
	-- urls
	['http']="<a href='http:@1@'>@2@</a>",
	['https']="<a href='https:@1@'>@2@</a>",
	['ref']="<a href='#@TYPE@:@ID@'>@ID@</a>",
	['img']="<img src='@0@'/>",
	

}



