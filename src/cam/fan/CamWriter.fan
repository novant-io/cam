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
    writeCol(k.name, k.type)
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
      writeCol(c.name, c.type)
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
      writeCell(val, c.type)
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
    if (val.getSafe(0) == '-') return true
    return val.any |ch| { ch == ',' || ch == '"' || ch == '\n' || ch == '\r' }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private OutStream out    // wrapped outstream
  private CamCol[] cols    // columns based last 'writeCols'
}
