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