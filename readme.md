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

Example:

```fantom
cam :=
 "@meta table employees
  id:Int, name,            started:Date, email
  1,      Bob Ross,        1983-10-15,   bob@paints.com
  2,      Barney Stinson,  2005-09-05,   barneye@gnb.com
  3,      George Costanza, 1989-03-10,   george@nyy.com
  ---
  @meta table roles
  id:Int, name
  1,      Marketing
  2,      Sales
  3,      HR"

// read employees
r := CamReader(cam.in)
m := r.readMeta
c := r.readCols
r.eachRow |r| { ... }

// next read roles (can skip readMeta/readCols)
r.eachRow |r| { ... }

// loop through all datasets
r := CamReader(cam.in)
while (r.hasDataset)
{
  m := r.readMeta
  r.eachRow |r| { ... }
}
```

