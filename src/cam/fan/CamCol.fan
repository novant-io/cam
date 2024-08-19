//
// Copyright (c) 2024, Novant LLC
// All Rights Reserved
//
// History:
//   18 Aug 2024  Andy Frank  Creation
//

*************************************************************************
** CamCol
*************************************************************************

@Js internal const class CamCol
{
  ** Parse a 'CamCol' instance from '"<name>[:<type>]"'.
  static new parse(Str token)
  {
    // defaults
    name := token
    type := Str#

    // then check for type declaration
    i := token.index(":")
    if (i != null)
    {
      name = token[0..<i]
      qname := token[i+1..-1]
      if (!qname.contains("::")) qname = "sys::${qname}"
      list := false
      if (qname.endsWith("[]"))
      {
        list = true
        qname = qname[0..-3]
      }
      type = Type.find(qname)
      if (list) type = type.toListOf
    }

    // verify name
    if (name.size == 0) throw IOErr("Column name cannot be empty")
    if (!name[0].isAlpha) throw IOErr("Column name must being with letter '${name}'")
    if (!name.all |c| { c.isAlphaNum || c == '_' }) throw IOErr("Invalid column name '${name}'")

    return CamCol(name, type)
  }

  ** Constructor.
  new make(Str name, Type type)
  {
    this.name = name
    this.type = type

    if (type.fits(List#))
    {
      // check for list type
      this.list = true
      this.listType = type.params["V"]
    }
  }

  const Str name
  const Type type
  const Bool list := false
  const Type? listType
}