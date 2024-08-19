//
// Copyright (c) 2024, Novant LLC
// All Rights Reserved
//
// History:
//   31 Jul 2024  Andy Frank  Creation
//

*************************************************************************
** CamWriterTest
*************************************************************************

class CamWriterTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    // meta
    buf := StrBuf()
    cam := CamWriter(buf.out)
    cam.writeMeta("foo", "bar-123")
    verifyEq(buf.toStr,
     """@meta foo bar-123
        """)

    // cols
    buf = StrBuf()
    cam = CamWriter(buf.out)
    cam.writeCols(["foo", "bar", "car"])
    verifyEq(buf.toStr,
     """foo,bar,car
        """)

    // sep
    buf = StrBuf()
    cam = CamWriter(buf.out)
    cam.writeSep
    verifyEq(buf.toStr,
     """---
        """)

    // rows
    buf = StrBuf()
    cam = CamWriter(buf.out)
    cam.writeCols(["foo",     "bar:Int", "car:Bool"])
    cam.writeRow([null,       12,        false])
    cam.writeRow(["alpha",    null,      false])
    cam.writeRow(["beta bar", 100,       null])
    verifyEq(buf.toStr,
     """foo,bar:Int,car:Bool
        ,12,false
        alpha,,false
        beta bar,100,
        """)
  }

  Void testSingleNullRow()
  {
// TODO: see note in CamReaderTest - not sure this is allowed
    // // rows
    // buf := StrBuf()
    // cam := CamWriter(buf.out)
    // cam.writeCols(["foo"])
    // cam.writeRow([null])
    // cam.writeRow([null])
    // cam.writeRow(["beta"])
    // cam.writeRow([null])
    // verifyEq(buf.toStr,
    //  """foo


    //     beta

    //     """)
  }

//////////////////////////////////////////////////////////////////////////
// Meta
//////////////////////////////////////////////////////////////////////////

  Void testMeta()
  {
    // meta
    buf := StrBuf()
    cam := CamWriter(buf.out)
    cam.writeMeta("alpha", "123")
    cam.writeMeta("beta",  "foo bar")
    cam.writeMeta("gamma:Str", "foo,bar,car")
    cam.writeMeta("delta_bravo_53", "cool")
    cam.writeMeta("empty", "")
    cam.writeMeta("int:Int", 12)
    verifyEq(buf.toStr,
     """@meta alpha 123
        @meta beta foo bar
        @meta gamma "foo,bar,car"
        @meta delta_bravo_53 cool
        @meta empty ""
        @meta int:Int 12
        """)

    // errs
    verifyMetaErr("", "foo")       // emtpy key
    verifyMetaErr("_err", "foo")   // non-alpha starter
    verifyMetaErr("1err", "foo")   // non-alpha starter
    verifyMetaErr("err#", "foo")   // invalid chars
    verifyMetaErr("err@", "foo")   // invalid chars
  }

  private Void verifyMetaErr(Str key, Obj val)
  {
    verifyErr(IOErr#) {
      buf := StrBuf()
      cam := CamWriter(buf.out)
      cam.writeMeta(key, val)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Cols
//////////////////////////////////////////////////////////////////////////

  Void testCols()
  {
    // ok
    verifyColOk("foo")
    verifyColOk("foo123")
    verifyColOk("foo_123")
    verifyColOk("foo_123_")
    verifyColOk("foo:Int")
    verifyColOk("foo:sys::Int")
    verifyColOk("foo:concurrent::AtomicBool")
    verifyColOk("foo:Str")
    verifyColOk("foo:Str[]")
    verifyColOk("foo:Int[]")
    verifyColOk("foo:sys::Bool[]")

    // errs
    verifyColErr("")             // empty col
    verifyColErr("_foo")         // non-alpha start
    verifyColErr("1_foo")        // non-alpha start
    verifyColErr("\"foo\"")      // quoted
    verifyColErr("foo bar")      // spaces
    verifyColErr("foo bar")      // spaces
    verifyColErr("foo:Integer")  // type not found
    verifyColErr("foo:sy::Int")  // type not found
  }

  private Void verifyColOk(Str col)
  {
    buf := StrBuf()
    cam := CamWriter(buf.out)
    cam.writeCols([col])
  }

  private Void verifyColErr(Str col)
  {
    verifyErr(IOErr#) {
      buf := StrBuf()
      cam := CamWriter(buf.out)
      cam.writeCols([col])
    }
  }

//////////////////////////////////////////////////////////////////////////
// Rows
//////////////////////////////////////////////////////////////////////////

  Void testRows()
  {
    // ok
    verifyRow("x",      null,  "")
    verifyRow("x",      "",    Str<|""|>)
    verifyRow("x",      "foo", Str<|foo|>)
    verifyRow("x:Int",  12,    Str<|12|>)
    verifyRow("x:Bool", false, Str<|false|>)

    // escaping
    verifyRow("x", Str<|foo bar|>,        Str<|foo bar|>)
    verifyRow("x", Str<|foo, bar|>,       Str<|"foo, bar"|>)
    verifyRow("x", Str<|foo "whoa" bar|>, Str<|"foo, ""bar"" bar"|>)
    verifyRow("x", "foo\nbar",            Str<|"foo\nbar"|>)
    verifyRow("x", "foo\rbar",            Str<|"foo\rbar"|>)
    verifyRow("x", "foo\tbar",            Str<|"foo\tbar"|>)
    verifyRow("x", "foo\bbar",            Str<|"foo\bbar"|>)

    // unicode
    verifyRow("x", "72°F",      Str<|72°F|>)
    verifyRow("x", "72\u00b0F", Str<|72°F|>)
  }

  private Void verifyRow(Str col, Obj? cell, Str expected)
  {
    buf := StrBuf()
    cam := CamWriter(buf.out)
    cam.writeCols([col])
    cam.writeRow([cell])
    return buf.toStr.splitLines.last
  }

//////////////////////////////////////////////////////////////////////////
// Multi
//////////////////////////////////////////////////////////////////////////

  Void testMulti()
  {
    buf := StrBuf()
    cam := CamWriter(buf.out)
    cam.writeMeta("foo:Int", 12)
    cam.writeMeta("bar", "cool beans")
    cam.writeCols(["alpha", "beta:Int", "gamma"])
    cam.writeRow(["a1",21,"g1"])
    cam.writeRow(["a2",22,"g2"])
    cam.writeSep
    cam.writeMeta("zar", "one, more, time")
    cam.writeCols(["delta", "epsilon", "zeta:Bool"])
    cam.writeRow(["d1","e1",false])
    cam.writeRow(["d2","e2",true])
    cam.writeSep
    cam.writeCols(["a", "b"])
    cam.writeRow(["---",55])
    cam.writeRow(["-",88])

    verifyEq(buf.toStr,
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
        a,b
        "---",55
        "-",88
        """)
  }
}