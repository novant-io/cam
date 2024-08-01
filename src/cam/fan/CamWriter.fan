//
// Copyright (c) 2024, Novant LLC
// All Rights Reserved
//
// History:
//   31 Jul 2024  Andy Frank  Creation
//

*************************************************************************
** CamWriter
*************************************************************************

@Js class CamWriter
{
  ** Construct a new CamWriter to wrap given out stream.
  new make(OutStream out)
  {
    this.out  = out
    this.cmap = Str:Type[:] { it.ordered=true }
  }

//////////////////////////////////////////////////////////////////////////
// Datasets
//////////////////////////////////////////////////////////////////////////

  ** Print a '@meta' key-value pair.
  This writeMeta(Str key, Obj val)
  {
    k := parseCol(key)
    out.print("@meta ")
    writeCol(k.first, k.last)
    out.writeChar(' ')
    writeCell(val, Str#)
    out.writeChar('\n')
    return this
  }

  ** Print a dataset separator.
  This writeSep()
  {
    out.printLine("---")
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Cols
//////////////////////////////////////////////////////////////////////////

  **
  ** Print column headers row. To type a column, append
  ** a colon and the type name: 'foo:Int'
  **
  This writeCols(Str[] cols)
  {
    // first parse columns and verify grammar
    cmap.clear
    cols.each |c|
    {
      p :=  parseCol(c)
      cmap[p.first] = p.last
    }

    // then render row
    cmap.keys.each |c,i|
    {
      if (i > 0) out.writeChar(',')
      t := cmap[c]
      writeCol(c, t)
    }

    out.writeChar('\n')
    return this
  }

  ** Print column name and type (if not Str#)
  private Void writeCol(Str name, Type type)
  {
    out.print(name)
    if (type != Str#)
    {
      out.writeChar(':')
      if (type.pod.name == "sys") out.print(type.name)
      else out.print(type.qname)
    }
  }

  ** Parse column into [Str name, Type type].
  private Obj[] parseCol(Str col)
  {
    if (col.size == 0)
      throw IOErr("Column cannot be empty")

    // column defaults
    name := col
    Type? type := Str#

    // check if type was specified
    off  := col.index(":")
    if (off != null)
    {
      name = col[0..<off]
      qname := col[off+1..-1]
      if (!qname.contains("::")) qname = "sys::${qname}"
      type = Type.find(qname, false)
      if (type == null) throw IOErr("Type not found '${qname}'")
    }

    // verify name grammar
    name.each |ch,i|
    {
      if (i == 0 && !ch.isAlpha)
        throw IOErr("Column must begin with letter '$col'")

      if (!ch.isAlphaNum && ch != '_')
        throw IOErr("Column may only contain letters, numbers, and underscore '$col'")
    }

    return [name, type]
  }

//////////////////////////////////////////////////////////////////////////
// Rows
//////////////////////////////////////////////////////////////////////////

  ** Print a row of cells.
  This writeRow(Obj?[] row)
  {
    // must match last writeCols
    if (row.size != cmap.size) throw IOErr("Row.size != col.size")

    cmap.keys.each |c,i|
    {
      type := cmap[c]
      val  := row[i]

      if (i > 0) out.writeChar(',')
      writeCell(val, type)
    }

    out.writeChar('\n')
    return this
  }

  private Void writeCell(Obj? val, Type type)
  {
    // no output if null
    if (val == null) return

    // convert to string and check if we need quotes
    str := val.toStr
    if (isQuoteReq(str))
    {
      // enclose and escape with quotes
      out.writeChar('"')
      val.toStr.each |ch|
      {
        if (ch == '"') out.writeChar('"')
        out.writeChar(ch)
      }
      out.writeChar('"')
    }
    else
    {
      // print raw string
      out.print(str)
    }
  }

  ** Return if given string requires being wrapped in quotes.
  private Bool isQuoteReq(Str? val)
  {
    if (val == null) return false
    if (val.isEmpty) return true
    return val.any |ch| { ch == ',' || ch == '"' || ch == '\n' || ch == '\r' }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private OutStream out   // wrapped outstream
  private Str:Type cmap   // map of column name:Type based on last 'writeCols'
}
