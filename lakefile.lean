import Lake
open Lake DSL System

package crypt where
  version := v!"0.1.0"
  moreLinkArgs := #["-L/opt/homebrew/lib", "-lsodium"]

require crucible from git "https://github.com/nathanial/crucible" @ "v0.0.1"

@[default_target]
lean_lib Crypt where
  roots := #[`Crypt]
  moreLinkArgs := #["-L/opt/homebrew/lib", "-lsodium"]

lean_lib Tests where
  roots := #[`Tests]

@[test_driver]
lean_exe crypt_tests where
  root := `Tests.Main
  moreLinkArgs := #["-L/opt/homebrew/lib", "-lsodium"]

-- FFI: Build C code with libsodium headers
target crypt_ffi_o pkg : FilePath := do
  let oFile := pkg.buildDir / "ffi" / "crypt_ffi.o"
  let srcJob ← inputTextFile <| pkg.dir / "ffi" / "crypt_ffi.c"
  let leanIncludeDir ← getLeanIncludeDir
  let weakArgs := #[
    "-I", leanIncludeDir.toString,
    "-I/opt/homebrew/include"
  ]
  buildO oFile srcJob weakArgs #["-fPIC", "-O2"] "cc" getLeanTrace

extern_lib crypt_native pkg := do
  let name := nameToStaticLib "crypt_native"
  let ffiO ← crypt_ffi_o.fetch
  buildStaticLib (pkg.buildDir / "lib" / name) #[ffiO]
