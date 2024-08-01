# Cam: Csv And More

Cam (Csv And More) is designed to be superset of CSV that can support multiple
datasets in a single stream, as well as provide additional semantics on each
dataset, including meta-data and column types:

    @meta table employees
    id:Int, name,            started:Date, email
    1,      Bob Ross,        1983-10-15,   bob@paints.com
    2,      Barney Stinson,  2005-09-05,   barneye@gnb.com
    3,      George Costanza, 1989-03-10,   george@nyy.com
    ---
    @meta table roles
    id:Int, name
    1,      Marketing
    2,      Sales
    3,      HR

## Directives

Extensions to the dataset are provided with directives:

    @<directive> [options] '\n'

### Metadata

Arbitrary meta data for the dataset can be provided with the `@meta` directive:

    @meta <key> ' ' <value> '\n'

Where the `key` follows same conventions as Column Names for grammar and
optional type support (see below) and `value` follows the same rules as
Record cells (see below) but must be non-null.

Example:

    @meta foo:Int 12
    @meta bar some string value
    id, name,     email
    1,  Bob Ross, bob@paints.com

## Columns

The first row of each dataset (following all, if any, directives) must contain
a column row that defines the record key names:

    id, name,     email
    1,  Bob Ross, bob@paints.com

### Column Name Format

The format for column names:

  * Must begin with a lowercase or uppercase letter
  * May contain any letter, digit, or underscore char
  * No other characters are allowed

### Column Types

By default all columns are typed as `Str` values.  A column can be typed using
a `:<type>` suffix in the header row:

    id:Int, name:Str, email
    1,      Bob Ross, bob@paints.com

Here, in each row the `id` value will be parsed into an `Int` instance instead
of a `Str` value.  Any type may be used here, as long as it supports
`toStr/fromStr` serialization.

Types from outside `sys` must specify the qualified type name:

    id:Int, name:Str, balance:money::Currency
    1,      Bob Ross, $1250.72

## Records

Following the column row, there is a row for each record in the dataset, where
there must exist a cell entry for each column.  Record rows follow the same
conventions as CSV as specified by RFC 4180:

  * Rows are delimited by a newline
  * Cells are separated by a comma `,` char
  * Cells may be quoted with `"` character
  * Quoted cells may contain the comma delimiter
  * Quoted cells may contain newlines (always normalized to `\n`)
  * Quoted cells must escape `"` with `""`

Differences from RFC 4180:

  * Cells _always_ trim leading/trailing whitespace
  * Empty cells are treated as `null`

To differentiate a `null` cell from an empty string, use quotes (`""`):

    id, thisIsNull, thisisEmptyStr
    1,  ,           ""

## Multiple Datasets

Multiple datasets can be included in a single Cam stream using the `---`
delimiter:

    @meta foo 12
    @meta bar "some string value"
    id, name,     email
    1,  Bob Ross, bob@paints.com
    ---
    @meta foo 52
    id, name,     email
    1,  Bob Ross, bob@paints.com

