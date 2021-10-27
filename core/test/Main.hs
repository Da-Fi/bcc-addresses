module Main where

import Prelude

import Bcc.Address.Compat
    ( ghcjsBuildSupport )
import Test.Hspec.Runner
    ( defaultConfig, hspecWith )

import qualified AutoDiscover

main :: IO ()
main = do
    ghcjsBuildSupport
    hspecWith defaultConfig AutoDiscover.spec
