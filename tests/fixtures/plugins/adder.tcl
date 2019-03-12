namespace eval adder {}

proc adder::add5 {n} {
  return [expr {$n+5}]
}

test adder::add5 {{ns t} {
  # Will pass
  set cases {
    {input 3 result 8}
    {input 7 result 12}
  }
  testCases $t $cases {{ns case} {dict with case {${ns}::add5 $input}}}
}}

test -id 2 adder::add5 {{ns t} {
  # Tests that testCases will fail
  set cases {
    {input 3 result 8}
    {input 7 result 12}
    {input 9 result 11}
  }
  testCases $t $cases {{ns case} {dict with case {${ns}::add5 $input}}}
}}


test -id 3 adder::add5 {{ns t} {
  # Tests testFail
  testFail $t "just want to fail"
}}
