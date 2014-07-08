module CabalCommon where

import qualified Cartel as C

versionInts :: [Int]
versionInts = [0,24]

base :: C.Package
base = C.closedOpen "base" [4,5,0,0] [5]

rainbowLower :: [Int]
rainbowLower = [0,14,0,0]

rainbowUpper :: [Int]
rainbowUpper = [0,15]

rainbow :: C.Package
rainbow = C.closedOpen "rainbow" rainbowLower rainbowUpper

rainbow_tests :: C.Package
rainbow_tests = C.closedOpen "rainbow-tests" rainbowLower rainbowUpper

text :: C.Package
text = C.closedOpen "text" [0,11,2,0] [1,2]

containers :: C.Package
containers = C.closedOpen "containers" [0,4,2,1] [0,6]

commonProperties :: C.Properties
commonProperties = C.empty
  { C.prVersion = C.Version versionInts
  , C.prLicenseFile = "LICENSE"
  , C.prCopyright = "Copyright 2013-2014 Omari Norman"
  , C.prAuthor = "Omari Norman"
  , C.prMaintainer = "omari@smileystation.com"
  , C.prStability = "Experimental"
  , C.prHomepage = "http://www.github.com/massysett/prednote"
  , C.prBugReports = "http://www.github.com/massysett/prednote/issues"
  , C.prCategory = "Data"
  }

repo :: C.Repository
repo = C.empty
  { C.repoVcs = C.Git
  , C.repoKind = C.Head
  , C.repoLocation = "git://github.com/massysett/prednote.git"
  , C.repoBranch = "master"
  }

ghcOptions :: [String]
ghcOptions = ["-Wall"]
