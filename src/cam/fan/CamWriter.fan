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
    this.cols = CamCol[,]
  }

//////////////////////////////////////////////////////////////////////////
// Datasets
//////////////////////////////////////////////////////////////////////////

  ** Print a '@meta' key-value pair.
  This writeMeta(Str key, Obj val)
  {
    k := parseCol(key)
    out.print("@meta ")
    writeCol(k)
    out.writeChar(' ')
    writeCell(val, k)
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
  This writeCols(Str[] columns)
  {
    // first parse columns and verify grammar
    this.cols.clear
    columns.each |c|
    {
      this.cols.add(parseCol(c))
    }

    // then render row
    this.cols.each |c,i|
    {
      if (i > 0) out.writeChar(',')
      writeCol(c)
    }

    out.writeChar('\n')
    return this
  }

  ** Print column name and type (if not Str#)
  private Void writeCol(CamCol col)
  {
    out.print(col.name)
    if (col.type != Str#)
    {
      out.writeChar(':')
      if (col.type.pod.name != "sys")
        out.print(col.type.pod.name).print("::")
      if (col.list)
        out.print(col.listType.name).print("[]")
      else
        out.print(col.type.name)
    }
  }

  ** Parse column into [Str name, Type type].
  private CamCol parseCol(Str col)
  {
    if (col.size == 0) throw IOErr("Column cannot be empty")
    return CamCol.parse(col)
  }

//////////////////////////////////////////////////////////////////////////
// Rows
//////////////////////////////////////////////////////////////////////////

  ** Print a row of cells.
  This writeRow(Obj?[] row)
  {
    // must match last writeCols
    if (row.size != cols.size) throw IOErr("Row.size != col.size")

    cols.each |c,i|
    {
      val := row[i]
      if (i > 0) out.writeChar(',')
      writeCell(val, c)
    }

    out.writeChar('\n')
    return this
  }

  private Void writeCell(Obj? val, CamCol col)
  {
    // no output if null
    if (val == null) return

    // convert to string
    str := col.list
      ? val.toStr[1..-2]   // TODO: more efficient way todo this?
      : val.toStr

    // check if we need to quotes
    if (isQuoteReq(str))
    {
      // enclose and escape with quotes
      out.writeChar('"')
      str.each |ch|
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
    if (val.getSafe(0) == '-') return true
    return val.any |ch| { ch == ',' || ch == '"' || ch == '\n' || ch == '\r' }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private OutStream out    // wrapped outstream
  private CamCol[] cols    // columns based last 'writeCols'
}
