{-# LANGUAGE OverloadedStrings #-}
module Main where

import Prednote
import Prelude hiding (any)

main :: IO ()
main = do
  _ <- ioTest (any $ equal (User "Int" []) (5 :: Int)) [0..10]
  _ <- ioTest (any $ equal (User "Int" []) (4 :: Int)) [0..3]
  return ()