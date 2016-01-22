# Lua-utils
light-weight, high-performed, flexible util libs for general purpose, implemented in pure Lua, including:
- org: utils to process text-based documents in `org-mode' like format, which can export to html, pdf(via latex), ...
- svg: utils to create svg via simple Lua API, where the basic apis are only four: Node, Edge, Export and Group. Plugins for special purpose are supported, including:
	- tree: visualize tree-like data automatically.
	- matrix: show matrix in svg canvas which are useful to illuminate algorithms.
	- flowchart: draw flowchat with different types of connections and shapes, where all connections can be generated in intuitive ways and arrows can pointed onto the border of shapes.
	- plot: plot 2d data as curve, bar, filled fields, ...
- math: utils to perform high-level science computations, including:
	- Set: incteract, union, exclude, product,...
	- Graph: (coming soon)