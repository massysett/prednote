{-# LANGUAGE OverloadedStrings, BangPatterns #-}

-- | Functions to work with 'Pred'.  This module works with 'Text' and
-- produces 'Pred' that make sparing use of color.  For more control
-- over the 'Pred' produced, use "Prednote.Pred.Core".
--
-- Exports some names that conflict with Prelude names, so you might
-- want to do something like
--
-- > import qualified Prednote.Pred as P
module Prednote.Pred where
{-
  ( 
  -- * Predicates
    C.Pred(..)

  -- * Visibility
  , C.Visible(..)
  , shown
  , hidden
  , reveal
  , hide
  , showTrue
  , showFalse

  -- * Predicate creation
  , predicate
  , true
  , false

  -- * Conjunction, disjunction, negation
  , all
  , (&&&)
  , any
  , (|||)
  , not

  -- * Fan
  , fanAll
  , fanAny
  , fanAtLeast

  -- * Display and evaluation
  , C.report
  , C.plan
  , C.test
  , C.testV
  , C.filter
  , C.filterV

  -- * Comparisons - overloaded
  , compare
  , equal
  , greater
  , less
  , greaterEq
  , lessEq
  , notEq

  -- * Comparisons - not overloaded
  , compareBy
  , equalBy
  , compareByMaybe
  , greaterBy
  , lessBy
  , greaterEqBy
  , lessEqBy
  , notEqBy

  -- * Comparers
  , parseComparer
  )where
-}

import qualified Prednote.Pred.Core as C
import Prednote.Pred.Core (Pred, Visible, Chunker, shown)
import qualified Data.Tree as E
import qualified Data.Text as X
import Data.Text (Text)
import System.Console.Rainbow
import Data.Monoid
import Prelude hiding (and, or, not, filter, compare, any, all)
import Control.Arrow (first)
import qualified Prelude

-- # Labels and indentation

lblTrue :: [Chunk]
lblTrue = ["[", f_green <> "TRUE", "]"]

lblFalse :: [Chunk]
lblFalse = ["[", f_red <> "FALSE", "]"]

indentAmt :: Int
indentAmt = 2

lblLine :: Bool -> Text -> [Chunk]
lblLine b t = lbl ++ [" ", fromText t]
  where
    lbl | b = lblTrue
        | otherwise = lblFalse

indent :: [Chunk] -> Int -> [Chunk]
indent cs i = spaces : cs ++ [fromText "\n"]
  where
    spaces = fromText . X.replicate (indentAmt * i)
      . X.singleton $ ' '

shortCir :: Int -> [Chunk]
shortCir = indent ["[", f_yellow <> "short circuit" <> "]"]

indentTxt :: Text -> Int -> [Chunk]
indentTxt = indent . (:[]) . fromText

(<+>) :: Text -> Text -> Text
l <+> r
  | full l && full r = l <> " " <> r
  | otherwise = l <> r
  where
    full = Prelude.not . X.null

-- # Predicate

rename :: Chunker -> Pred a -> Pred a
rename c p = p { C.static = t' }
  where
    t' = (C.static p) { E.rootLabel = c }

changeOutput
  :: (a -> C.Output -> C.Output)
  -> Pred a
  -> Pred a
changeOutput f p = p { C.evaluate = e' }
  where
    e' a = t'
      where
        t = C.evaluate p a
        t' = t { E.rootLabel = f a (E.rootLabel t) }

speak :: (a -> Text) -> C.Pred a -> C.Pred a
speak f = changeOutput g
  where
    g a o = o { C.dynamic = dyn }
      where
        dyn = indent $ lblLine (C.result o) (f a)


speakShort :: C.Pred a -> C.Pred a
speakShort p = p { C.evaluate = e' }
  where
    e' a = t { E.rootLabel = (E.rootLabel t)
      { C.short = fmap (const shortCir) shrt } }
      where
        t = C.evaluate p a
        shrt = C.short . E.rootLabel $ t

predicate :: (a -> Text) -> (a -> Bool) -> C.Pred a
predicate s f = speak s $ C.Pred (E.Node (const []) []) ev
  where
    ev a = E.Node (C.Output (f a) C.shown Nothing (const [])) []

-- | Always returns 'True' and is always visible.
true :: Pred a
true = predicate (const "always True") (const True)

-- | Always returns 'False' and is always visible.
false :: Pred a
false = predicate (const "always False") (const False)

{-
-- # Visibility

visibility :: (Bool -> Visible) -> Pred a -> Pred a
visibility f (Pred s e) = Pred s e'
  where
    e' a = g (e a)
    g (Node n cs) = Node n { visible = f (result n) } cs

reveal :: Pred a -> Pred a
reveal = visibility (const shown)

hide :: Pred a -> Pred a
hide = visibility (const hidden)

showTrue :: Pred a -> Pred a
showTrue = visibility (\b -> if b then shown else hidden)

showFalse :: Pred a -> Pred a
showFalse = visibility (\b -> if Prelude.not b then shown else hidden)


-- # Conjunction and disjunction, negation

-- | No child 'Pred' may be 'False'.  An empty list of child 'Pred'
-- returns 'True'.  Always visible.
all :: [Pred a] -> Pred a
all = C.all (indentTxt "all") shortCir dyn
  where
    dyn b _ = indent $ lblLine b "all"

-- | Creates 'all' 'Pred' that are always visible.
(&&&) :: Pred a -> Pred a -> Pred a
l &&& r = all [l, r]

infixr 3 &&&

-- | At least one child 'Pred' must be 'True'.  An empty list of child
-- 'Pred' returns 'False'.  Always visible.

any :: [Pred a] -> Pred a
any = C.any (indentTxt "any") shortCir dyn
  where
    dyn b _ = indent $ lblLine b "any"

-- | Creates 'or' 'Pred' that are always visible.
(|||) :: Pred a -> Pred a -> Pred a
l ||| r = any [l, r]

infixr 2 |||

-- | Negation.  Always visible.
not :: Pred a -> Pred a
not = C.not (indentTxt "not") dyn
  where
    dyn b _ = indent $ lblLine b "not"

-- | No fanned-out item may be 'False'.  An empty list of child items
-- returns 'True'.
fanAll :: (a -> [b]) -> Pred b -> Pred a
fanAll = C.fanAll (indentTxt lbl) shortCir dyn
  where
    lbl = "fanout all - no fanned-out subject may be False"
    dyn b _ = indent $ lblLine b lbl

-- | At least one fanned-out item must be 'True'.  An empty list of
-- child items returns 'False'.
fanAny :: (a -> [b]) -> Pred b -> Pred a
fanAny = C.fanAny (indentTxt lbl) shortCir dyn
  where
    lbl = "fanout any - one fanned-out subject must be True"
    dyn b _ = indent $ lblLine b lbl

-- | At least the given number of child items must be 'True'.
fanAtLeast :: Int -> (a -> [b]) -> Pred b -> Pred a
fanAtLeast i = C.fanAtLeast i (indentTxt lbl) shortCir dyn
  where
    lbl = "fanout at least - at least " <> X.pack (show i)
      <> " fanned-out subject(s) must be True"
    dyn b _ = indent $ lblLine b lbl

-- # Comparisons

-- | Build a Pred that compares items.  The idea is that the item on
-- the right hand side is baked into the 'Pred' and that the 'Pred'
-- compares this single right-hand side to each left-hand side item.
compareBy
  :: Text
  -- ^ Description of the type of thing that is being matched

  -> Text
  -- ^ Description of the right-hand side

  -> Ordering
  -- ^ When subjects are compared, this ordering must be the result in
  -- order for the Predbox to be True; otherwise it is False. The subject
  -- will be on the left hand side.

  -> (a -> (Ordering, Text))
  -- ^ The first of the pair is how to compare an item against the
  -- right hand side. Return LT if the item is less than the right
  -- hand side; GT if greater; EQ if equal to the right hand side.
  --
  -- The second of the pair is a description of the left hand side.

  -> Pred a

compareBy typeDesc rhsDesc ord get = predicate stat fn
  where
    stat = typeDesc <+> "is" <+> ordDesc <+> rhsDesc
    ordDesc = case ord of
      EQ -> "equal to"
      LT -> "less than"
      GT -> "greater than"
    fn a = (res, shown, dyn)
      where
        (ord', txt) = get a
        res = ord' == ord
        dyn = typeDesc <+> txt <+> "is" <+> ordDesc <+> rhsDesc

-- | Builds a 'Pred' that tests items for equality.

equalBy
  :: Text
  -- ^ Description of the type of thing that is being matched

  -> Text
  -- ^ Description of the right-hand side

  -> (a -> (Bool, Text))
  -- ^ The first of the pair is how to compare an item against the
  -- right hand side. Return True if the items are equal; False otherwise.
  --
  -- The second of the pair is a description of the left hand side.

  -> Pred a
equalBy typeDesc rhsDesc get = predicate stat fn
  where
    stat = typeDesc <+> "is equal to" <+> rhsDesc
    fn a = (res, shown, dyn)
      where
        (res, txt) = get a
        dyn = typeDesc <+> txt <+> "is equal to" <+> rhsDesc

-- | Overloaded version of 'equalBy'.

equal
  :: (Eq a, Show a)
  => Text
  -- ^ Description of the type of thing that is being matched

  -> a
  -- ^ Right-hand side

  -> Pred a
equal typeDesc rhs = equalBy typeDesc (X.pack . show $ rhs) f
  where
    f lhs = (lhs == rhs, X.pack . show $ lhs)

-- | Overloaded version of 'compareBy'.

compare
  :: (Show a, Ord a)
  => Text
  -- ^ Description of the type of thing that is being matched

  -> Ordering
  -- ^ When subjects are compared, this ordering must be the result in
  -- order for the Predbox to be True; otherwise it is False. The subject
  -- will be on the left hand side.

  -> a
  -- ^ Right-hand side

  -> Pred a

compare typeDesc ord rhs = compareBy typeDesc rhsDesc ord fn
  where
    fn lhs = (Prelude.compare lhs rhs, X.pack . show $ lhs)
    rhsDesc = X.pack . show $ rhs

-- | Builds a 'Pred' for items that might fail to return a comparison.
compareByMaybe
  :: Text
  -- ^ Description of the type of thing that is being matched

  -> Text
  -- ^ Description of the right-hand side

  -> Ordering
  -- ^ When subjects are compared, this ordering must be the result in
  -- order for the Predbox to be True; otherwise it is False. The subject
  -- will be on the left hand side.

  -> (a -> (Maybe Ordering, Text))
  -- ^ The first of the pair is how to compare an item against the
  -- right hand side. Return LT if the item is less than the right
  -- hand side; GT if greater; EQ if equal to the right hand side.
  --
  -- The second of the pair is a description of the left hand side.

  -> Pred a

compareByMaybe typeDesc rhsDesc ord get = predicate stat fn
  where
    stat = typeDesc <+> "is" <+> ordDesc <+> rhsDesc
    ordDesc = case ord of
      EQ -> "equal to"
      LT -> "less than"
      GT -> "greater than"
    fn a = (res, shown, dyn)
      where
        (ord', txt) = get a
        res = case ord' of
          Nothing -> False
          Just o -> o == ord
        dyn = typeDesc <+> txt <+> "is" <+> ordDesc <+> rhsDesc

greater
  :: (Show a, Ord a)

  => Text
  -- ^ Description of the type of thing being matched

  -> a
  -- ^ Right-hand side

  -> Pred a
greater typeDesc = compare typeDesc GT


less
  :: (Show a, Ord a)

  => Text
  -- ^ Description of the type of thing being matched

  -> a
  -- ^ Right-hand side

  -> Pred a
less typeDesc = compare typeDesc GT

greaterEq
  :: (Show a, Ord a)
  => Text
  -- ^ Description of the type of thing being matched

  -> a
  -- ^ Right-hand side

  -> Pred a
greaterEq t r = greater t r ||| equal t r

lessEq
  :: (Show a, Ord a)
  => Text
  -- ^ Description of the type of thing being matched

  -> a
  -- ^ Right-hand side

  -> Pred a
lessEq t r = less t r ||| equal t r

notEq
  :: (Show a, Ord a)
  => Text
  -- ^ Description of the type of thing being matched

  -> a
  -- ^ Right-hand side

  -> Pred a
notEq t r = not $ equal t r

greaterBy
  :: Text
  -- ^ Description of the type of thing being matched

  -> Text
  -- ^ Description of right-hand side

  -> (a -> (Ordering, Text))
  -- ^ The first of the pair is how to compare an item against the
  -- right hand side. Return LT if the item is less than the right
  -- hand side; GT if greater; EQ if equal to the right hand side.
  --
  -- The second of the pair is a description of the left hand side.

  -> Pred a
greaterBy dT dR f = compareBy dT dR GT f


lessBy
  :: Text
  -- ^ Description of the type of thing being matched

  -> Text
  -- ^ Description of right-hand side

  -> (a -> (Ordering, Text))
  -- ^ The first of the pair is how to compare an item against the
  -- right hand side. Return LT if the item is less than the right
  -- hand side; GT if greater; EQ if equal to the right hand side.
  --
  -- The second of the pair is a description of the left hand side.

  -> Pred a
lessBy dT dR f = compareBy dT dR LT f

greaterEqBy
  :: Text
  -- ^ Description of the type of thing being matched

  -> Text
  -- ^ Description of right-hand side

  -> (a -> (Ordering, Text))
  -- ^ The first of the pair is how to compare an item against the
  -- right hand side. Return LT if the item is less than the right
  -- hand side; GT if greater; EQ if equal to the right hand side.
  --
  -- The second of the pair is a description of the left hand side.

  -> Pred a
greaterEqBy dT dR f = greaterBy dT dR f ||| equalBy dT dR f'
  where
    f' = fmap (first (== EQ)) f

lessEqBy
  :: Text
  -- ^ Description of the type of thing being matched

  -> Text
  -- ^ Description of right-hand side

  -> (a -> (Ordering, Text))
  -- ^ The first of the pair is how to compare an item against the
  -- right hand side. Return LT if the item is less than the right
  -- hand side; GT if greater; EQ if equal to the right hand side.
  --
  -- The second of the pair is a description of the left hand side.

  -> Pred a
lessEqBy dT dR f = lessBy dT dR f ||| equalBy dT dR f'
  where
    f' = fmap (first (== EQ)) f

notEqBy
  :: Text
  -- ^ Description of the type of thing being matched

  -> Text
  -- ^ Description of right-hand side

  -> (a -> (Bool, Text))
  -- ^ The first of the pair is how to compare an item against the
  -- right hand side. Return True if the items are equal; False if not.
  --
  -- The second of the pair is a description of the left hand side.

  -> Pred a
notEqBy dT dR f = not $ equalBy dT dR f


parseComparer
  :: Text
  -- ^ The string with the comparer to be parsed
  -> (Ordering -> Pred a)
  -- ^ A function that, when given an ordering, returns a Predbox
  -> Maybe (Pred a)
  -- ^ If an invalid comparer string is given, Nothing; otherwise, the
  -- Predbox.
parseComparer t f
  | t == ">" = Just (f GT)
  | t == "<" = Just (f LT)
  | t == "=" = Just (f EQ)
  | t == "==" = Just (f EQ)
  | t == ">=" = Just (f GT ||| f EQ)
  | t == "<=" = Just (f LT ||| f EQ)
  | t == "/=" = Just (not $ f EQ)
  | t == "!=" = Just (not $ f EQ)
  | otherwise = Nothing



-}