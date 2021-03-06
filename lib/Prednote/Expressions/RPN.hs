{-# LANGUAGE OverloadedStrings #-}
-- | Postfix, or RPN, expression parsing.
--
-- This module parses RPN expressions where the operands are
-- predicates and the operators are one of @and@, @or@, or @not@,
-- where @and@ and @or@ are binary and @not@ is unary.
module Prednote.Expressions.RPN where

import qualified Data.Foldable as Fdbl
import qualified Prednote.Core as P
import Prednote.Core ((&&&), (|||), PredM)
import Data.Monoid ((<>))
import Data.Text (Text)
import qualified Data.Text as X

data RPNToken f a
  = TokOperand (PredM f a)
  | TokOperator Operator

data Operator
  = OpAnd
  | OpOr
  | OpNot
  deriving Show

pushOperand :: PredM f a -> [PredM f a] -> [PredM f a]
pushOperand p ts = p : ts

pushOperator
  :: (Monad m, Functor m)
  => Operator
  -> [PredM m a]
  -> Either Text [PredM m a]
pushOperator o ts = case o of
  OpAnd -> case ts of
    x:y:zs -> return $ (y &&& x) : zs
    _ -> Left $ err "and"
  OpOr -> case ts of
    x:y:zs -> return $ (y ||| x) : zs
    _ -> Left $ err "or"
  OpNot -> case ts of
    x:zs -> return $ P.not x : zs
    _ -> Left $ err "not"
  where
    err x = "insufficient operands to apply \"" <> x
            <> "\" operator\n"

pushToken
  :: (Functor f, Monad f)
  => [PredM f a]
  -> RPNToken f a
  -> Either Text [PredM f a]
pushToken ts t = case t of
  TokOperand p -> return $ pushOperand p ts
  TokOperator o -> pushOperator o ts

-- TODO improve "Bad expression" error message?

-- | Parses an RPN expression and returns the resulting 'Pred'. Fails if
-- there are no operands left on the stack or if there are multiple
-- operands left on the stack; the stack must contain exactly one
-- operand in order to succeed.
parseRPN
  :: (Functor m, Monad m)
  => Fdbl.Foldable f
  => f (RPNToken m a)
  -> Either Text (PredM m a)
parseRPN ts = do
  trees <- Fdbl.foldlM pushToken [] ts
  case trees of
    [] -> Left $ "bad expression: no operands left on the stack\n"
    x:[] -> return x
    xs -> Left . X.pack
      $ "bad expression: multiple operands left on the stack:\n"
      <> concatMap show xs

