const c1: string = "Hello Nim"

type
  TestObj = object
    t1 : pointer
    t2 : string
    t3 : int

proc kmain() {.exportc.} =
  var x = @[1, 2, 3, 4, 5, 6]
  let cpyseq = x
  var tstr : string = "teststring"
  var t  = TestObj(t1:nil,t2:c1,t3:0)
  let xy = "teststring"
  echo c1
  echo xy 
  echo tstr
  echo t.t2