{-# OPTIONS_GHC -fno-warn-missing-signatures #-}

module Prednote.Core.Properties where

import Prednote.Core.Instances ()
import Prednote.Core
import Test.QuickCheck.Function
import Prelude hiding (not, any, all)
import qualified Prelude

testInt :: Pred Int -> Int -> Bool
testInt = test

prop_predicateIsLazyInArguments (Fun _ f) i
  = testInt (predicate undefined f) i || True

prop_predicateIsSameAsOriginal (Fun _ f) i
  = testInt (predicate undefined f) i == f i

prop_andIsLazyInSecondArgument i
  = testInt (false &&& undefined) i || True

prop_orIsLazyInSecondArgument i
  = testInt (true ||| undefined) i || True

prop_andIsLikePreludeAnd (Fun _ f1) (Fun _ f2) i
  = testInt (p1 &&& p2) i == (f1 i && f2 i)
  where
    p1 = predicate undefined f1
    p2 = predicate undefined f2

prop_orIsLikePreludeOr (Fun _ f1) (Fun _ f2) i
  = testInt (p1 ||| p2) i == (f1 i || f2 i)
  where
    p1 = predicate undefined f1
    p2 = predicate undefined f2

prop_notIsLikePreludeNot (Fun _ f1) i
  = testInt (not p1) i == Prelude.not (f1 i)
  where
    p1 = predicate undefined f1

prop_switchIsLazyInFirstArgument pb i
  = test (switch undefined pb) (Right i) || True
  where
    _types = pb :: Pred Int
    
prop_switchIsLazyInSecondArgument pa i
  = test (switch pa undefined) (Left i) || True
  where
    _types = pa :: Pred Int

prop_switch (Fun _ fa) (Fun _ fb) ei
  = test (switch pa pb) ei == expected
  where
    _types = ei :: Either Int Char
    expected = case ei of
      Left i -> fa i
      Right c -> fb c
    pa = predicate undefined fa
    pb = predicate undefined fb
    
prop_true = testInt true

prop_false = Prelude.not . testInt false

prop_same b = test same b == b

prop_any (Fun _ f) ls
  = test (any pa) ls == Prelude.any f ls
  where
    pa = predicate undefined f
    _types = ls :: [Int]
    
prop_all (Fun _ f) ls
  = test (all pa) ls == Prelude.all f ls
  where
    pa = predicate undefined f
    _types = ls :: [Int]
    