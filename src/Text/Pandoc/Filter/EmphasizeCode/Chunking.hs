{-# LANGUAGE CPP               #-}
{-# LANGUAGE OverloadedStrings #-}

module Text.Pandoc.Filter.EmphasizeCode.Chunking
  ( LineChunk(..)
  , EmphasizedLine
  , EmphasizedLines
  , emphasizeRanges
  ) where

import           Data.HashMap.Strict                       (HashMap)
import qualified Data.HashMap.Strict                       as HashMap
import           Data.List                                 (foldl')
import           Data.Text                                 (Text)
import qualified Data.Text                                 as Text

import           Text.Pandoc.Filter.EmphasizeCode.Position
import           Text.Pandoc.Filter.EmphasizeCode.Range

data LineChunk
  = Literal Text
  | Emphasized EmphasisStyle
               Text
  deriving (Show, Eq)

chunkText :: LineChunk -> Text
chunkText (Literal t)      = t
chunkText (Emphasized _ t) = t

type EmphasizedLine = [LineChunk]

type EmphasizedLines = [EmphasizedLine]

emphasizeRanges :: HashMap Line [SingleLineRange] -> Text -> EmphasizedLines
emphasizeRanges ranges contents = zipWith chunkLine (Text.lines contents) [1 ..]
  where
    chunkLine line' lineNr =
      let (rest, _, chunks) =
            foldl'
              chunkRange
              (line', 0, [])
              (HashMap.lookupDefault [] lineNr ranges)
      in filter (not . Text.null . chunkText) (chunks ++ [Literal rest])
    chunkRange ::
         (Text, Column, EmphasizedLine)
      -> SingleLineRange
      -> (Text, Column, EmphasizedLine)
    chunkRange (lineText, offset, chunks) r =
      case Text.splitAt startIndex lineText of
        (before, rest) ->
          case singleLineRangeEnd r of
            Just end ->
              let endIndex = fromIntegral (end - offset) - Text.length before
                  (emph, rest') = Text.splitAt endIndex rest
                  newOffset =
                    offset +
                    fromIntegral (Text.length lineText - Text.length rest')
              in ( rest'
                 , newOffset
                 , chunks ++ [Literal before, Emphasized style emph])
            Nothing ->
              ( ""
              , offset + fromIntegral (Text.length lineText)
              , chunks ++ [Literal before, Emphasized style rest])
      where
        startIndex = fromIntegral (singleLineRangeStart r - 1 - offset)
        style = singleLineRangeStyle r
