{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
module Prednote.Prebuilt.Properties where

import Rainbow.Types.Instances ()
import Prednote.Prebuilt
import Prednote.Prebuilt.Instances
import Test.QuickCheck.Function
import qualified Prelude
import Prelude hiding (not, either, maybe, any, all)


testInt :: Pdct Int -> Int -> Bool
testInt = test

prop_predicateDoesSameAsFunction ts txt (Fun _ f) i
  = testInt (predicate ts txt f) i == f i

prop_trueReturnsTrue = testInt true

prop_falseReturnsFalse = Prelude.not . testInt false

prop_sameReturnsSame b = test same b == b

prop_wrapSameAsOriginal (PdctParts _ _ (Fun _ f1) p1) (Fun _ f2)
  ts char
  = (test (wrap ts f2 p1) char) == (f1 (f2 char))
  where
    _types = (char :: Char, f1 :: Int -> Bool)

prop_andDoesSameAsPreludeAnd ts1 txt1 (Fun _ f1)
  ts2 txt2 (Fun _ f2) i
  = (testInt (p1 &&& p2) i) == (f1 i && f2 i)
  where
    p1 = predicate ts1 txt1 f1
    p2 = predicate ts2 txt2 f2

prop_andShortCircuitsOnFalse i
  = (testInt (false &&& (Pdct undefined undefined)) i) == False

prop_orDoesSameAsPreludeOr ts1 txt1
  (Fun _ f1) ts2 txt2 (Fun _ f2) i
  = (testInt (p1 ||| p2) i) == (f1 i || f2 i)
  where
    p1 = predicate ts1 txt1 f1
    p2 = predicate ts2 txt2 f2

prop_orShortCircuitsOnTrue i
  = ((testInt (true ||| Pdct undefined undefined)) i) == True

prop_notDoesSameAsPreludeNot ts txt (Fun _ f) i
  = (testInt (not $ predicate ts txt f) i) == (Prelude.not (f i))

-- either

prop_eitherWorksOnEitherSide
  (PdctParts _ _ (Fun _ f1) p1) (PdctParts _ _ (Fun _ f2) p2) ei
  = case ei of
      Left i -> r == f1 (i :: Int)
      Right i -> r == f2 (i :: Int)
  where
    r = test (either p1 p2) ei


-- anyOfPair

prop_anyOfPair ts (Fun _ split)
  (PdctParts _ _ (Fun _ f1) p1) (PdctParts _ _ (Fun _ f2) p2) i
  = (testInt (anyOfPair ts split p1 p2) i)
      == (f1 int || f2 char)
  where
    (int, char) = split i
    _types = (p1 :: Pdct Int, p2 :: Pdct Char)

prop_anyOfPairLazyInFirstArgument ts (Fun _ split) i
  = (testInt (anyOfPair ts split true undefined) i) || True
  where
    _types = split :: Int -> (Char, Int)

-- bothOfPair

prop_bothOfPair ts (Fun _ split)
  (PdctParts _ _ (Fun _ f1) p1) (PdctParts _ _ (Fun _ f2) p2) i
  = (testInt (bothOfPair ts split p1 p2) i)
      == (f1 int && f2 char)
  where
    (int, char) = split i
    _types = (p1 :: Pdct Int, p2 :: Pdct Char)


prop_bothOfPairLazyInFirstArgument ts (Fun _ split) i
  = (testInt (bothOfPair ts split false undefined) i) || True
  where
    _types = split :: Int -> (Char, Int)

-- any

prop_anySameAsPreludeAny
  (PdctParts _ _ (Fun _ f1) p1) ls
  = (test (any p1) ls) == (Prelude.any f1 ls)
  where
    _types = ls :: [Int]

prop_anyShortCircuitsOnTrue = test (any same) (True : undefined)

-- all

prop_allSameAsPreludeAll
  (PdctParts _ _ (Fun _ f1) p1) ls
  = (test (all p1) ls) == (Prelude.all f1 ls)
  where
    _types = ls :: [Int]

prop_allShortCircuitsOnFalse = Prelude.not $ test (all same)
  (False : undefined)

-- maybe

prop_maybe
  (PdctParts _ _ (Fun _ f1) p1) (PdctParts _ _ (Fun _ f2) p2) may
  = case may of
      Nothing -> r == f1 ()
      Just i -> r == f2 (i :: Int)
  where
    r = test (maybe p1 p2) may
