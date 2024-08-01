#! /usr/bin/env fan

using build

class Build : build::BuildPod
{
  new make()
  {
    podName = "cam"
    summary = "Cam file format API"
    version = Version("1.0")
    meta = [
      "org.name":     "Novant",
      "org.uri":      "https://novant.io/",
      "license.name": "MIT",
      "vcs.name":     "Git",
      "vcs.uri":      "https://github.com/novant-io/cam",
      "repo.public":  "true",
      "repo.tags":    "",
    ]
    depends = ["sys 1.0"]
    srcDirs = [`fan/`, `test/`]
    // docApi   = false   // defaults to 'true'
    // docSrc   = true    // defaults to 'false'
  }
}
