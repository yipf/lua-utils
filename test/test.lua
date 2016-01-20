require "test-utils"

dofile "/home/yipf/lua-utils/config.lua"
require "math/Set"

A=Set{1,2,3,4,5}
B=Set{2,3,4,6}

Eval "A"
Eval "B"
Eval "A+B"
Eval "B+A"
Eval "B-A"
Eval "A-B"
Eval "A/B"
Eval "A*B"
Eval "B*A"
Eval "B^A"
Eval "A^B"
Eval "B*A+(A-B)"
Eval "A==B"
Eval "A==B*A+(A-B)"
Eval "A*B==B*A"
Eval "A^B==B^A"



