//
// Copyright (c) 2024, Novant LLC
// All Rights Reserved
//
// History:
//   31 Jul 2024  Andy Frank  Creation
//

*************************************************************************
** CamReader
*************************************************************************

@Js class CamReader
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** Construct a new reader for given input stream.
  new make(InStream in)
  {
    this.in = in
    this.tempBuf = StrBuf(128)
  }

//////////////////////////////////////////////////////////////////////////
// Datasets
//////////////////////////////////////////////////////////////////////////

  ** Return 'true' if stream has additional dataset(s) available.
  Bool hasDataset()
  {
    // eat any leading whitespace
    while (peek != null && peek.isSpace) read

    // NOTE: we do not validate the next char;
    // let readMeta/ReadCols do that
    return peek != null
  }

//////////////////////////////////////////////////////////////////////////
// Meta
//////////////////////////////////////////////////////////////////////////

  ** Read all '@meta' fields from current stream position.
  Str:Obj readMeta()
  {
    // verify remaining data
    if (!hasDataset) throw unexpectedEos

    // check for meta
    meta := Str:Obj[:]
    while (peek == '@')
    {
      op := readToken(' ')
      switch (op)
      {
        case "@meta":
          key := readCol(' ')
          val := readCell(key.last)
          if (val == null) throw IOErr("Missing @meta value for '${key.first}'")
          meta[key.first] = val

        default: throw IOErr("Unsupported directive '@${op}'")
      }
    }
    return meta
  }

//////////////////////////////////////////////////////////////////////////
// Cols
//////////////////////////////////////////////////////////////////////////

  ** Read columns and return an ordered map of column name and type.
  Str:Type readCols()
  {
    // verify remaining data
    if (!hasDataset) throw unexpectedEos

    // check if we need to eat unread meta
    if (peek == '@') readMeta

    cmap := Str:Type[:] { it.ordered=true }
    while (peek != null)
    {
      c := readCol
      cmap[c.first] = c.last
      if (lastLineEnd) break
    }

    // stash col meta for readRows
    this.colNames = cmap.keys
    this.colTypes = cmap.vals

    return cmap
  }

  ** Read column and return [Str name, Type type].
  private Obj[] readCol(Int delim := ',')
  {
    // read whole token first
    token := readToken(delim)
    if (token == null) throw IOErr("Expecting column def")
    name := token
    type := Str#

    // then check for type declaration
    i := token.index(":")
    if (i != null)
    {
      name = token[0..<i]
      qname := token[i+1..-1]
      if (!qname.contains("::")) qname = "sys::${qname}"
      type = Type.find(qname)
    }

    // verify name
    if (name.size == 0) throw IOErr("Column name cannot be empty")
    if (!name[0].isAlpha) throw IOErr("Column name must being with letter '${name}'")
    if (!name.all |c| { c.isAlphaNum || c == '_' }) throw IOErr("Invalid column name '${name}'")

    return [name, type]
  }

//////////////////////////////////////////////////////////////////////////
// Rows
//////////////////////////////////////////////////////////////////////////

  ** Read the next line as a row of delimiter-separated values
  ** based on the last `readCols`. Return null if at the end of
  ** the current dataset or end of stream.
  Obj?[]? readRow()
  {
    doReadRow(0)
  }

  ** Read the next line as a map of column names to delimiter
  ** separated values based on the last `readCols`. Return null
  ** if at the end of the current dataset or end of stream.
  [Str:Obj?]? readRowMap()
  {
    doReadRow(1)
  }

  ** Iterate through all the lines parsing each one into
  ** delimited-separated values based on the last `readCols`
  ** and calling the given callback functions.
  Void eachRow(|Obj?[] row| f)
  {
    while (true)
    {
      row := readRow
      if (row == null) break
      f(row)
    }
  }

  ** Iterate through all the lines parsing each one into a map
  ** of column name to delimited-separated value based  on the
  ** last `readCols` and calling the given callback functions.
  Void eachRowMap(|Str:Obj?[] row| f)
  {
    while (true)
    {
      row := readRowMap
      if (row == null) break
      f(row)
    }
  }

  ** Read next row into List or Map accumulator.
  private Obj? doReadRow(Int acctype)
  {
    // check if we need to read cols
    if (colNames == null) readCols

    // eat leading whitepsace
    while (peek != null && peek.isSpace) read

    // check eos
    if (peek == null) return null

    // check for set separator
    if (peek == '-')
    {
      if (read != '-') throw unexpectedChar(last)
      if (read != '-') throw unexpectedChar(last)
      if (read != '-') throw unexpectedChar(last)

      // reset cols
      colNames = null
      colTypes = null
      return null
    }

    // init accumulator
    acc := acctype == 0
      ? Obj?[,] { it.capacity=colNames.size }
      : Str:Obj?[:]

    // read next row
    index := 0
    while (peek != null)
    {
      type := colTypes.getSafe(index) ?: throw IOErr("Row width != col width")
      cell := readCell(type)
      if (acctype == 0) ((Obj?[])acc).add(cell)
      else
      {
        // omit null values from map for memory performance
        if (cell != null) {
          key := colNames[index]
          ((Str:Obj?)acc).set(key, cell)
        }
      }
      index++
      if (lastLineEnd) break
    }

    // sanity check
    if (index != colNames.size) throw IOErr("Row width != col width")

    return acc
  }

  ** Read the next cell value.
  private Obj? readCell(Type type)
  {
    // read raw text
    text := readToken

    // unqouted empty text is always null
    if (text == null) return null

    // parse text based on 'type'
    switch (type)
    {
      case Str#: return text
      default:  return type.method("fromStr").call(text)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Read Support
//////////////////////////////////////////////////////////////////////////

  ** Read token.
  private Str? readToken(Int delim := ',')
  {
    // eat leading whitespace
    while (peek == ' ') read

    // read next token into temp buf
    tempBuf.clear

    // check for quoted token
    if (peek == '"')
    {
      // quoted token
      ch := read  // eat opening "
      ch = read
      while (true)
      {
        if (ch == '"')
        {
          // escaped quote; read and continue; else break
          if (peek == '"') ch = read
          else break
        }

        // else append and advance
        tempBuf.addChar(ch)
        ch = read
      }

      // eat delim and trim trailing whitepace
      while (peek == ' ') read
      read
      return tempBuf.toStr
    }
    else
    {
      // unquoted token
      while (peek != delim && !peekLineEnd) {
        tempBuf.addChar(read)
      }

      // eat delim and trim trailing whitepace
      read
      return tempBuf.toStr.trimToNull
    }
  }

//////////////////////////////////////////////////////////////////////////
// Stream Support
//////////////////////////////////////////////////////////////////////////

  ** Read next char in stream or 'null' if EOS.
  private Int? read()
  {
    last = in.readChar
    return last
  }

  ** Peek next char in stream without reading or 'null' if EOS.
  private Int? peek() { in.peekChar }

  ** Return 'true' if next char is an EOS or newline without reading.
  private Bool peekLineEnd() { in.peekChar == null || in.peekChar == '\n' }

  ** Return 'true' if last char read was an EOS or newline.
  private Bool lastLineEnd() { last == '\n' }

  private Err unexpectedEos()
  {
    IOErr("Unexpected EOS")
  }

  private Err unexpectedChar(Int? ch)
  {
    ch == null
      ? unexpectedEos
      : IOErr("Unexpected char '${ch.toChar}'")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private InStream in
  private Int? last          // last char read
  private StrBuf tempBuf     // resusable working buffer
  private Str[]? colNames    // column names from last readCols
  private Type[]? colTypes   // column types from last readCols
}
