local concat,gsub,format=table.concat,string.gsub,string.format

local TABLE_PAT=[[
\begin{table}[!hbp]
\centering
\begin{tabular}{@FORMAT@}
@VALUE@
\end{tabular}
\caption{\label{@TYPE@:@ID@}@CAPTION@}
\end{table}
]]

local FIGURE_PAT=[[
\begin{figure}[!htb]
\centering
\includegraphics{@VALUE@}
\caption{\label{@TYPE@:@ID@}@CAPTION@}
\end{figure}
]]

local EQ_PAT=[[
\begin{equation} \label{@TYPE@:@ID@}
@VALUE@
\end{equation}
]]

local refs=function(str)
	return format([[
\bibliographystyle{plain}
\bibliography{%s}
]],str)
end

local COMPILE_PAT=[[
xelatex -interaction=nonstopmode @name@.tex
xelatex -interaction=nonstopmode @name@.tex
rm @name@.nav @name@.toc @name@.log @name@.aux @name@.out @name@.snm
]]


local TABLE= {
	EXT='tex',
	OL="\n\\begin{enumerate}\n@VALUE@\n\\end{enumerate}",
	UL="\n\\begin{itemize}\n@VALUE@\n\\end{itemize}",
	LI=[[\item{@VALUE@}]],
	
	TOC="\\tableofcontents",
	TOC_ITEM="",
	TOC_OF_TYPE="",
	
	REFERENCES=refs,
	
	['img']=[[\begin{figure}
\centering
\includegraphics[width=0.9\textwidth]{@1@}
\end{figure}]],
	
	["SEC*"]="\n\\section*{@CAPTION@} \n@VALUE@",
	["SUBSEC*"]="\n\\subsection*{@CAPTION@} \n@VALUE@",
	["SUBSUBSEC*"]="\n\\subsection*{@CAPTION@} \n@VALUE@",
	["SUBSUBSUBSEC*"]="\n\\subsection*{@CAPTION@}\n@VALUE@",
	
	['TABLE_ROW']=function(row,i) 
		return concat(row," & ").." \\\\";
	end,
	['TABLE_MAIN']=function(o)
		o.FORMAT=o.FORMAT or string.rep("c ",o.COLS)
		o.VALUE="\\hline\n"..o[1].."\n\\hline\n"..concat(o,"\n",2).."\n\\hline"
		return (gsub(TABLE_PAT,"@%s*(.-)%s*@",o))
	end,
	
	
		TABLE=function(o)
		local t={}
		local r={}
		local n,rn=0
		local gmatch,insert=string.gmatch,table.insert
		for l in gmatch(o.VALUE.."\n","(.-)\n") do
			n=n+1
			rn=0
			for c in gmatch(l,"([^|]+)") do
				rn=rn+1
				r[rn]=c
			end
			if rn>1 then
				t[n]=table.concat(r,"&",1,rn)..[[\\]]
			end
		end
		if o.ROWLINES=="TRUE" then
			o.VALUE="\\hline\n"..table.concat(t,"\n\\hline\n").."\n\\hline"
		else
			t[2]=t[2].."\n\\hline"
			o.VALUE="\\hline\n"..table.concat(t,"\n").."\n\\hline"
		end
		o.FORMAT=o.FORMAT or string.rep("c",#r)
		return gsub(TABLE_PAT,"@(.-)@",o)
	end,
	
	BLOCK="\n\\begin{@TYPE@}\n@VALUE@\n\\end{@TYPE@}",
	
	P="@VALUE@",
--~ 	
	
	['em']="\\emph{@0@}",
	-- urls
	['http']="<a href='http:@1@'>@2@</a>",
	['https']="<a href='https:@1@'>@2@</a>",
	['cite']="\\cite{@0@}",
	['ref']="\\ref{@TYPE@:@ID@}",
	
	['CODE']="CODE.@ID@ @CAPTION@ \\label{@TYPE@:@ID@}",
	
		code="\\lstinputlisting[language=@1@,style=customcode]{@2@}",
	['code-part']="\\lstinputlisting[language=@1@,style=customcode,firstline=@3@,lastline=@4@,firstnumber=@3@,lastnumber=@4@]{@2@}",
	
--~ 	['EQ']=EQ_PAT,

--~ 	['FIG']=FIGURE_PAT,
	
	[0]=[[
\documentclass{article}
\usepackage{hyperref}
\usepackage{graphicx}
\usepackage{listings}
\usepackage{xcolor}
\usepackage{amsfonts}
\usepackage{amsmath}
\usepackage{cite}

\lstdefinestyle{customcode}{
  belowcaptionskip=1\baselineskip,
  breaklines=true,
  xleftmargin=20pt,
  frame=single,
  showstringspaces=false,
  numbers=left,                    % where to put the line-numbers; possible values are (none, left, right)
  numbersep=10pt,                   % how far the line-numbers are from the code
  numberstyle=\tiny\color{gray}, % the style that is used for the line-numbers
  basicstyle=\footnotesize\ttfamily,
  keywordstyle=\bfseries\color{blue}, 
  identifierstyle=\color{purple!40!black},
  commentstyle=\itshape\color{green!40!black},
  stringstyle=\color{orange},
}

\title{@CAPTION@}
\author{@AUTHOR@}
\date{@DATE@}

\usepackage{xltxtra,fontspec,xunicode}
\usepackage[slantfont,boldfont]{xeCJK} % 允许斜体和粗体

\setCJKmainfont{WenQuanYi Micro Hei}   % 设置缺省中文字体 徐静蕾字体

\begin{document}
\maketitle
\tableofcontents  \newpage
@VALUE@
\bibliographystyle{plain}
\end{document}]],

--~ 	[1]="\n\\chapter{@CAPTION@} \\label{@TYPE@:@ID@}\n@VALUE@",
	[1]="\n\\section{@CAPTION@} \\label{@TYPE@:@ID@}\n@VALUE@",
	[2]="\n\\subsection{@CAPTION@} \\label{@TYPE@:@ID@}\n@VALUE@",
	[3]="\n\\subsubsection{@CAPTION@} \\label{@TYPE@:@ID@}\n@VALUE@",

	['$']=[[\(@0@\)]], -- inline eq
	['*']="\\emph{@0@}", -- em
	['`']=[["@0@"]], -- quote
	
	["toc"]="\\tableofcontents",
	["toc-block"]="",
	["toc-item"]="",
	
	timeuse="[@1@]",
	
	post_process=function(name)
		local str=string.gsub(COMPILE_PAT,"@name@",name)
		local f=io.popen(str)
		if f then
			print(f:read("*a"))
			f:close()
		end
	end,
	
}


return TABLE
