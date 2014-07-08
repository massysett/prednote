-- | Exports some names that conflict with Prelude names, so you might
-- want to do something like
--
-- > import qualified Prednote as P
module Prednote
  ( module Prednote.Pred
  , module Prednote.Expressions
  ) where

import Prednote.Pred
import Prednote.Expressions