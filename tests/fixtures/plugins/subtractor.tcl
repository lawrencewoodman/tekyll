namespace eval subtractor {}

proc subtractor::sub5 {n} {
  return [expr {$n-5}]
}

test subtractor::sub5 {{ns t} {
  # Will pass
  set cases {
    {input 3 result -2}
    {input 7 result 2}
  }
  testCases $t $cases {{ns case} {dict with case {${ns}::sub5 $input}}}
}}
