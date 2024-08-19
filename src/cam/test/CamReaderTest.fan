//
// Copyright (c) 2024, Novant LLC
// All Rights Reserved
//
// History:
//   31 Jul 2024  Andy Frank  Creation
//

*************************************************************************
** CamReaderTest
*************************************************************************

class CamReaderTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Empty
//////////////////////////////////////////////////////////////////////////

  Void testEmpty()
  {
    // empty
    r := CamReader("".in)
    verifyEq(r.hasDataset, false)

    // empty with whitespace
    r = CamReader("         ".in)
    verifyEq(r.hasDataset, false)

    // empty with newlines
    r = CamReader(
        "


         ".in)
    verifyEq(r.hasDataset, false)
  }

//////////////////////////////////////////////////////////////////////////
// Meta
//////////////////////////////////////////////////////////////////////////

  Void testMeta()
  {
    // type:Str
    verifyMeta("@meta foo bar",     ["foo":"bar"])
    verifyMeta("@meta foo:Str bar", ["foo":"bar"])
    verifyMeta(   "@meta   foo     bar    ", ["foo":"bar"])

    // type:Int
    verifyMeta("@meta foo:Int 12",  ["foo":12])
    verifyMeta("@meta foo:Int -53", ["foo":-53])

    // type:Bool
    verifyMeta("@meta foo:Bool true",  ["foo":true])
    verifyMeta("@meta foo:Bool false", ["foo":false])

    // multiple values
    verifyMeta(
      "@meta alpha:Int 10
       @meta beta:Bool true
       @meta gamma     bar 123",
       ["alpha":10, "beta":true, "gamma":"bar 123"])

    // errs
    verifyMetaErr("")
    verifyMetaErr("@meta")
    verifyMetaErr("@meta foo")
    verifyMetaErr("@foo")
  }

  private Void verifyMeta(Str cam, Str:Obj expect)
  {
    dumb := Str:Obj[:].setAll(expect)

    r := CamReader(cam.in)
    verifyEq(r.readMeta, dumb)
  }

  private Void verifyMetaErr(Str cam)
  {
    verifyErr(IOErr#) {
      r := CamReader(cam.in)
      r.readMeta
    }
  }

//////////////////////////////////////////////////////////////////////////
// Cols
//////////////////////////////////////////////////////////////////////////

  Void testCols()
  {
    // basics
    verifyCols("alpha",            ["alpha",Str#])
    verifyCols("alpha,beta,gamma", ["alpha",Str#,"beta",Str#,"gamma",Str#])
    verifyCols("  alpha ,   beta ,  gamma  ", ["alpha",Str#,"beta",Str#,"gamma",Str#])

    // valid chars
    verifyCols("a",   ["a",Str#])
    verifyCols("a1",  ["a1",Str#])
    verifyCols("a_1", ["a_1",Str#])
    verifyCols(Str<|"a"|>,   ["a",Str#])
    verifyCols(Str<|"a1"|>,  ["a1",Str#])
    verifyCols(Str<|"a_1"|>, ["a_1",Str#])

    // types
    verifyCols("a",           ["a",Str#])
    verifyCols("a:Str",       ["a",Str#])
    verifyCols("a:sys::Str",  ["a",Str#])
    verifyCols("a:Int",       ["a",Int#])
    verifyCols("a:sys::Int",  ["a",Int#])
    verifyCols("a:Date",      ["a",Date#])
    verifyCols("a:sys::Date", ["a",Date#])
    verifyCols("a:Int[]",     ["a",Int[]#])
    verifyCols("a:sys::Bool[]", ["a",Bool[]#])
    verifyCols("a:concurrent::AtomicBool", Obj["a",Type.find("concurrent::AtomicBool")])
    verifyCols(Str<|"a:sys::Str"|>,  ["a",Str#])
    verifyCols(Str<|"a:Int"|>,       ["a",Int#])
    verifyCols(Str<|"a:sys::Date"|>, ["a",Date#])

    // test with meta and rows
    c :=
     "@meta foo 12
      alpha,beta,gamma
      a1,b1,g1
      a2,b2,g2"
    verifyCols(c, ["alpha",Str#,"beta",Str#,"gamma",Str#])

    // test with meta and rows
    r := CamReader(
     "@meta foo 12
      a,b,c
      ".in)
    verifyEq(r.readMeta, Str:Obj["foo":"12"])
    verifyColsX(r.readCols, ["a",Str#, "b",Str#, "c",Str#])
    verifyEq(r.readRow, null)

    // errs
    verifyColErr("")
    verifyColErr("_a")
    verifyColErr("123")
  }

  private Void verifyCols(Str cam, Obj[] expect)
  {
    t := Obj[,]
    r := CamReader(cam.in)
    verifyEq(r.hasDataset, true)
    r.readCols.each |v,k| { t.add(k).add(v) }
    verifyEq(t, expect)
  }

  private Void verifyColErr(Str cam)
  {
    verifyErr(IOErr#) {
      r := CamReader(cam.in)
      r.readCols
    }
  }

//////////////////////////////////////////////////////////////////////////
// Rows
//////////////////////////////////////////////////////////////////////////

  Void testReadRow()
  {
    // single row
    r := CamReader(
     "alpha,beta,gamma
      a1,b1,g1".in)
    verifyEq(r.readRow, Obj?["a1","b1","g1"])
    verifyEq(r.readRow, null)

    // multiple rows
    r = CamReader(
     "alpha,beta,gamma
      a1,b1,g1
      a2,b2,g2
      a3,b3,g3".in)
    verifyEq(r.readRow, Obj?["a1","b1","g1"])
    verifyEq(r.readRow, Obj?["a2","b2","g2"])
    verifyEq(r.readRow, Obj?["a3","b3","g3"])
    verifyEq(r.readRow, null)

    // multiple rows with whitespace
    r = CamReader(
     "alpha,beta,gamma
        a1,  b1    ,g1
      a2 , b2,  g2
       a3   ,  b3  ,  g3  ".in)
    verifyEq(r.readRow, Obj?["a1","b1","g1"])
    verifyEq(r.readRow, Obj?["a2","b2","g2"])
    verifyEq(r.readRow, Obj?["a3","b3","g3"])
    verifyEq(r.readRow, null)

    // trailing whitespace
    r = CamReader(
     "alpha,beta,gamma
      a1,b1,g1
      a2,b2,g2
      a3,b3,g3


      ".in)
    verifyEq(r.readRow, Obj?["a1","b1","g1"])
    verifyEq(r.readRow, Obj?["a2","b2","g2"])
    verifyEq(r.readRow, Obj?["a3","b3","g3"])
    verifyEq(r.readRow, null)

    // mixed newlines
    r = CamReader(
     "alpha,beta,gamma

      a1,b1,g1


      a2,b2,g2


      a3,b3,g3


      ".in)
    verifyEq(r.readRow, Obj?["a1","b1","g1"])
    verifyEq(r.readRow, Obj?["a2","b2","g2"])
    verifyEq(r.readRow, Obj?["a3","b3","g3"])
    verifyEq(r.readRow, null)

    // null values
    r = CamReader(
     "alpha,beta,gamma
      ,b1,g1
      a2,b2,
      a3,,g3".in)
    verifyEq(r.readRow, Obj?[null,"b1","g1"])
    verifyEq(r.readRow, Obj?["a2","b2",null])
    verifyEq(r.readRow, Obj?["a3",null,"g3"])
    verifyEq(r.readRow, null)

// TODO: we might need to disallow this unless we tighten
//       other rules about empty lines?
    // // empy null row values
    // r = CamReader(
    //  "foo


    //   n1

    //   ".in)
    // verifyEq(r.readRow, Obj?[null])
    // verifyEq(r.readRow, Obj?[null])
    // verifyEq(r.readRow, Obj?["n1"])
    // verifyEq(r.readRow, Obj?[null])
    // verifyEq(r.readRow, null)

    // types
    r = CamReader(
     "alpha,beta:Int,gamma:Date
      ,5,2024-08-01
      a2,7,
      a3,,2024-07-31".in)
    verifyEq(r.readRow, Obj?[null, 5,    Date("2024-08-01")])
    verifyEq(r.readRow, Obj?["a2", 7,    null])
    verifyEq(r.readRow, Obj?["a3", null, Date("2024-07-31")])
    verifyEq(r.readRow, null)

    // list types
    r = CamReader(
     Str<|alpha,beta:Int[],gamma:Date
          ,5,2024-08-01
          a2,,
          a3,"1,2,3,4",2024-07-31
          a4,"",2024-08-02
          |>.in)
    verifyEq(r.readRow, Obj?[null, Int[5], Date("2024-08-01")])
    verifyEq(r.readRow, Obj?["a2", null, null])
    verifyEq(r.readRow, Obj?["a3", Int[1,2,3,4], Date("2024-07-31")])
    verifyEq(r.readRow, Obj?["a4", Int[,],       Date("2024-08-02")])
    verifyEq(r.readRow, null)

    // escaping (quoted)
    verifyRow("x", "\"foo, bar\"", "foo, bar")
    verifyRow("x", "\"foo bar\"",  "foo bar")
    verifyRow("x", "\"foo\bbar\"", "foo\bbar")
    verifyRow("x", "\"foo\tbar\"", "foo\tbar")
    verifyRow("x", "\"foo\nbar\"", "foo\nbar")
    verifyRow("x", "\"foo\rbar\"", "foo\rbar")
    verifyRow("x", Str<|"foo ""whoa"" bar"|>, "foo \"whoa\" bar")
    verifyRow("x", Str<|"foo
                        bar"|>, "foo\nbar")

    // escaping (non-quoted)
    verifyRow("x", "foo bar",  "foo bar")
    verifyRow("x", "foo\bbar", "foo\bbar")
    verifyRow("x", "foo\tbar", "foo\tbar")
    verifyRow("x", "foo\rbar", "foo\rbar")

    // mixed quote/unquote
    r = CamReader(
     Str<|alpha,beta,gamma
          "a",b,c
          a,"b",c
          a,b,"c"
           "a"  , b ,  c
          a,  "b" ,c
          a,b,     "c"  |>.in)
    verifyEq(r.readRow, Obj?["a","b","c"])
    verifyEq(r.readRow, Obj?["a","b","c"])
    verifyEq(r.readRow, Obj?["a","b","c"])
    verifyEq(r.readRow, Obj?["a","b","c"])
    verifyEq(r.readRow, Obj?["a","b","c"])
    verifyEq(r.readRow, Obj?["a","b","c"])
    verifyEq(r.readRow, null)

    // null vs empty string
    r = CamReader(
     Str<|alpha,beta,gamma
          ,"",
          "",,
          ,,""
          |>.in)
    verifyEq(r.readRow, Obj?[null,"",null])
    verifyEq(r.readRow, Obj?["",null,null])
    verifyEq(r.readRow, Obj?[null, null,""])
    verifyEq(r.readRow, null)

    // rows with @
    r = CamReader(
     "@meta foo:Int 12
      @meta bar man this is cool
      alpha, beta, gamma:Bool
      ,      b1,   false
      @5,    b2,
      100,   b3,   true".in)
    verifyEq(r.hasDataset, true)
    verifyEq(r.readMeta, ["foo":12, "bar":"man this is cool"])
    verifyEq(r.readRow,  Obj?[null, "b1", false])
    verifyEq(r.readRow,  Obj?["@5", "b2", null])
    verifyEq(r.readRow,  Obj?["100","b3", true])
    verifyEq(r.readRow, null)

    // full grid
    r = CamReader(
     "@meta foo:Int 12
      @meta bar man this is cool
      alpha:Int, beta, gamma:Bool
      ,          b1,   false
      5,         b2,
      100,       ,     true".in)
    verifyEq(r.hasDataset, true)
    verifyEq(r.readMeta, ["foo":12, "bar":"man this is cool"])
    verifyEq(r.readRow,  [null, "b1", false])
    verifyEq(r.readRow,  [5,    "b2", null])
    verifyEq(r.readRow,  [100,  null, true])
    verifyEq(r.readRow, null)
  }

  Void testReadRowMap()
  {
   // single row
    r := CamReader(
     "alpha,beta,gamma
      a1,b1,g1".in)
    verifyEq(r.readRowMap, Str:Obj?["alpha":"a1", "beta":"b1", "gamma":"g1"])
    verifyEq(r.readRowMap, null)

    // multiple rows
    r = CamReader(
     "alpha,beta,gamma
      a1,b1,g1
      a2,b2,g2
      a3,b3,g3".in)
    verifyEq(r.readRowMap, Str:Obj?["alpha":"a1", "beta":"b1", "gamma":"g1"])
    verifyEq(r.readRowMap, Str:Obj?["alpha":"a2", "beta":"b2", "gamma":"g2"])
    verifyEq(r.readRowMap, Str:Obj?["alpha":"a3", "beta":"b3", "gamma":"g3"])
    verifyEq(r.readRowMap, null)

    // null values (omit null keys in readRowMap)
    r = CamReader(
     "alpha,beta,gamma
      ,b1,g1
      a2,b2,
      a3,,g3".in)
    verifyEq(r.readRowMap, Str:Obj?["beta":"b1",  "gamma":"g1"])
    verifyEq(r.readRowMap, Str:Obj?["alpha":"a2", "beta":"b2"])
    verifyEq(r.readRowMap, Str:Obj?["alpha":"a3", "gamma":"g3"])
    verifyEq(r.readRowMap, null)

    // types
    r = CamReader(
     "alpha,beta:Int,gamma:Date
      ,5,2024-08-01
      a2,7,
      a3,,2024-07-31".in)
    verifyEq(r.readRowMap, Str:Obj?["beta":5, "gamma":Date("2024-08-01")])
    verifyEq(r.readRowMap, Str:Obj?["alpha":"a2", "beta":7])
    verifyEq(r.readRowMap, Str:Obj?["alpha":"a3", "gamma":Date("2024-07-31")])
    verifyEq(r.readRowMap, null)
  }

  Void testEachRow()
  {
    rows := [,]
    reader := CamReader(
     "alpha,beta,gamma
      a1,b1,g1
      a2,b2,g2
      a3,b3,g3".in)
    reader.eachRow |r| { rows.add(r) }

    verifyEq(rows.size, 3)
    verifyEq(rows[0], Obj?["a1","b1","g1"])
    verifyEq(rows[1], Obj?["a2","b2","g2"])
    verifyEq(rows[2], Obj?["a3","b3","g3"])
  }

  Void testEachRowMap()
  {
    rows := [,]
    reader := CamReader(
     "alpha,beta,gamma
      a1,b1,g1
      a2,b2,g2
      a3,b3,g3".in)
    reader.eachRowMap |r| { rows.add(r) }

    verifyEq(rows.size, 3)
    verifyEq(rows[0], Str:Obj?["alpha":"a1", "beta":"b1", "gamma":"g1"])
    verifyEq(rows[1], Str:Obj?["alpha":"a2", "beta":"b2", "gamma":"g2"])
    verifyEq(rows[2], Str:Obj?["alpha":"a3", "beta":"b3", "gamma":"g3"])
  }

  private Void verifyRow(Str col, Str row, Obj? expect)
  {
    c := "${col}\n${row}"
    r := CamReader(c.in)
    verifyEq(r.readRow.first, expect)
  }

//////////////////////////////////////////////////////////////////////////
// Multi
//////////////////////////////////////////////////////////////////////////

  Void testMulti()
  {
    // basics
    rows := [,]
    r := CamReader(
     """@meta foo:Int 12
        @meta bar cool beans
        alpha,beta:Int,gamma
        a1,21,g1
        a2,22,g2
        ---
        @meta zar "one, more, time"
        delta,epsilon,zeta:Bool
        d1,e1,false
        d2,e2,true
        ---
        @meta car:Bool true
        a,b,c
        """.in)
    // dataset 1
    verifyEq(r.hasDataset, true)
    verifyEq(r.hasDataset, true)  // check dup calls
    verifyEq(r.readMeta, Str:Obj["foo":12, "bar":"cool beans"])
    verifyColsX(r.readCols, ["alpha",Str#, "beta",Int#, "gamma",Str#])
    r.eachRow |row| { rows.add(row) }
    verifyEq(rows[0], Obj?["a1", 21, "g1"])
    verifyEq(rows[1], Obj?["a2", 22, "g2"])
    // dataset 2
    verifyEq(r.hasDataset, true)
    verifyEq(r.readMeta, Str:Obj["zar":"one, more, time"])
    verifyColsX(r.readCols, ["delta",Str#, "epsilon",Str#, "zeta",Bool#])
    rows.clear
    r.eachRow |row| { rows.add(row) }
    verifyEq(rows[0], Obj?["d1", "e1", false])
    verifyEq(rows[1], Obj?["d2", "e2", true])
    // dataset 3
    verifyEq(r.hasDataset, true)
    verifyEq(r.readMeta, Str:Obj["car":true])
    rows.clear
    r.eachRow |row| { rows.add(row) }
    verifyEq(rows.size, 0)
    verifyEq(r.hasDataset, false)
    verifyEq(r.hasDataset, false)  // check dup calls

    // test leading/trailing whitespace
    r = CamReader(
     """@meta foo:Int 12
        @meta bar cool beans
        alpha,beta:Int,gamma
        a1,21,g1
        a2,22,g2

        ---


        @meta zar "one, more, time"
        delta,epsilon,zeta:Bool
        d1,e1,false
        d2,e2,true


        ---

        @meta car:Bool true
        a,b,c


        """.in)
    // dataset 1
    verifyEq(r.hasDataset, true)
    verifyEq(r.hasDataset, true)  // check dup calls
    verifyEq(r.readMeta, Str:Obj["foo":12, "bar":"cool beans"])
    verifyColsX(r.readCols, ["alpha",Str#, "beta",Int#, "gamma",Str#])
    r.eachRow |row| { rows.add(row) }
    verifyEq(rows[0], Obj?["a1", 21, "g1"])
    verifyEq(rows[1], Obj?["a2", 22, "g2"])
    // dataset 2
    verifyEq(r.hasDataset, true)
    verifyEq(r.readMeta, Str:Obj["zar":"one, more, time"])
    verifyColsX(r.readCols, ["delta",Str#, "epsilon",Str#, "zeta",Bool#])
    rows.clear
    r.eachRow |row| { rows.add(row) }
    verifyEq(rows[0], Obj?["d1", "e1", false])
    verifyEq(rows[1], Obj?["d2", "e2", true])
    // dataset 3
    verifyEq(r.hasDataset, true)
    verifyEq(r.readMeta, Str:Obj["car":true])
    rows.clear
    r.eachRow |row| { rows.add(row) }
    verifyEq(rows.size, 0)
    verifyEq(r.hasDataset, false)
    verifyEq(r.hasDataset, false)  // check dup calls
  }

  Void testMultiEach()
  {
    metas := [,]
    sets  := [,]

    cr := CamReader(
     """@meta foo:Int 12
        @meta bar cool beans
        alpha,beta:Int,gamma
        a1,21,g1
        a2,22,g2
        ---
        delta,epsilon,zeta:Bool
        d1,e1,false
        d2,e2,true
        ---
        @meta car:Bool true
        a,b,c
        """.in)

    while (cr.hasDataset)
    {
      rows := [,]
      metas.add(cr.readMeta)
      cr.eachRow |r| { rows.add(r) }
      sets.add(rows)
    }

    verifyEq(metas[0], Str:Obj["foo":12, "bar":"cool beans"])
    verifyEq(sets[0], Obj?[
      Obj?["a1", 21, "g1"],
      Obj?["a2", 22, "g2"],
    ])

    verifyEq(metas[1], Str:Obj[:])
    verifyEq(sets[1], Obj?[
      Obj?["d1", "e1", false],
      Obj?["d2", "e2", true],
    ])

    verifyEq(metas[2], Str:Obj["car":true])
    verifyEq(sets[2], Obj?[,])
  }

  private Void verifyColsX(Str:Type cols, Obj[] expect)
  {
    t := Obj[,]
    cols.each |v,k| { t.add(k).add(v) }
    verifyEq(t, expect)
  }
}