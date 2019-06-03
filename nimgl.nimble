# Package

version     = "0.3.6"
author      = "Leonardo Mariscal"
description = "Nim Game Library"
license     = "MIT"
srcDir      = "src"
skipDirs    = @[".circleci", ".github", "examples"]

# Dependencies

requires "nim >= 0.18.0"

# Tasks

import
  strutils

const
  docDir = "docs"

before test:
  when defined(vcc):
    echo("Installing Visual Studio Variables")
    exec(r"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars32.bat")

proc nimExt(file: string): bool =
  var ext = ".nim"
  for n in 0 ..< ext.len:
    if file[file.len - (n + 1)] != ext[ext.len - (n + 1)]:
      return false
  return true

proc genDocs(pathr: string, output: string) =
  var
    path = pathr.replace(r"\", "/")
    src = path[4 .. path.len - 5]
    sp = path.split("/")
  echo "\n[info] generating " & src & ".nim"

  discard sp.pop
  mkDir(docDir & sp.join("/").substr(3))
  exec("nim doc -o:" & output & "/" & src & ".html" & " " & path)

proc walkRecursive(dir: string) =
  for f in listFiles(dir):
    if f.nimExt: genDocs(f, docDir)
  for od in listDirs(dir):
    if od != "private": walkRecursive(od)

task test, "test stuff under examples dir":
  exec("nimble install -y glm")
  for file in listFiles("examples"):
    if file[9] == 't' and file.nimExt:
      echo "\n[info] testing " & file[6..<file.len]
      #exec("nim c --verbosity:0 --hints:off -r " & file)
      exec("nim c -d:opengl_debug " & file)

task general, "run examples/general.nim which is the general test for dev":
  exec("nim c -r -d:opengl_debug examples/timgui.nim")

task docs, "Generate Documentation for all of the Library":
  walkRecursive(srcDir)
