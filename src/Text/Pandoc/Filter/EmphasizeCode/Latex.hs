{-# LANGUAGE CPP               #-}
{-# LANGUAGE OverloadedStrings #-}

module Text.Pandoc.Filter.EmphasizeCode.Latex
  ( Latex(Latex)
  ) where
#if MIN_VERSION_base(4,8,0)
import           Data.Semigroup                              ((<>))
#else
import           Control.Applicative
import           Data.Monoid
#endif
import           Data.Char                                   (isSpace)
import qualified Data.Text                                   as Text
import qualified Text.Pandoc.Definition                      as Pandoc

import           Text.Pandoc.Filter.EmphasizeCode.Chunking
import           Text.Pandoc.Filter.EmphasizeCode.Range
import           Text.Pandoc.Filter.EmphasizeCode.Renderable

data Latex =
  Latex

instance Renderable Latex where
  renderEmphasized _ (_, classes, _) lines' =
    Pandoc.RawBlock
      (Pandoc.Format "latex")
      (Text.unpack (encloseInVerbatim emphasized))
    where
      languageAttr =
        case classes of
          [lang] -> ",language=" <> Text.pack lang
          _      -> ""
      encloseInTextIt style t
        | Text.null t = t
        | otherwise =
          case style of
            Inline -> "£\\CodeEmphasis{" <> t <> "}£"
            Block  -> "£\\CodeEmphasisLine{" <> t <> "}£"
      emphasizeNonSpace style t
        | Text.null t = t
        | otherwise =
          let (nonSpace, rest) = Text.break isSpace t
              (spaces, rest') = Text.span isSpace rest
          in mconcat
               [ encloseInTextIt style nonSpace
               , spaces
               , emphasizeNonSpace style rest'
               ]
      emphasizeChunk chunk =
        case chunk of
          Literal t          -> t
          Emphasized style t -> emphasizeNonSpace style t
      emphasized = Text.unlines (map (foldMap emphasizeChunk) lines')
      encloseInVerbatim t =
        mconcat
          [ "\\begin{lstlisting}[escapechar=£"
          , languageAttr
          , "]\n"
          , t
          , "\\end{lstlisting}\n"
          ]
