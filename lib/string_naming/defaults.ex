defmodule StringNaming.Defaults do
  @moduledoc false

  @spec categories :: [binary()]
  def categories do
    ~w|
      AdditionalPunctuation
      AlternateFormsOfPunctuation
      ArchaicPunctuation
      AsciiPunctuation
      AsciiPunctuationAndSymbols
      CjkSymbolsAndPunctuation
      DictionaryPunctuation
      GeneralPunctuation
      GenericPunctuationForPhilippineScripts
      GenericPunctuationForScriptsOfIndia
      HalfwidthCjkPunctuation
      HistoricPunctuation
      KatakanaPunctuation
      Latin1PunctuationAndSymbols
      MiscellaneousPunctuation
      OldNubianPunctuation
      OtherCjkPunctuation
      PairedPunctuation
      PointsAndPunctuation
      PunctaExtraordinaria
      Punctuation
      PunctuationForTibetan
      PunctuationMark
      PunctuationMarkOrnaments
      ReversedPunctuation
      SyriacPunctuationAndSigns

      ArchaicRomanNumerals
      AsciiDigits
      AstrologicalDigits
      CircledNumbers
      Digits
      DigitsMinusHalf
      DingbatCircledDigits
      DoubleStruckDigits
      FullwidthAsciiVariants
      HistoricalDigits
      HistoricalNumbers
      HundredThousands
      Hundreds
      NumberForms
      NumberJoiner
      NumberWithFullStop
      Numbers
      NumbersPeriod
      NumbersWithComma
      NumeralSigns
      Numerals
      NumericCharacter
      NumericSigns
      NumericSymbolsForDivinationLore
      ParenthesizedNumbers
      RomanNumerals
      SansSerifDigits
      ShanDigits
      SuzhouNumerals
      TamilNumerics
      TenThousands
      Tens
      ThamDigits
      Thousands
      Threes
      TurnedDigits
      WhiteOnBlackCircledNumbers

      Space
      Spaces
      SpacingAccentMarks
      SpacingClonesOfDiacritics
      SpecificSymbolsForSpace
    |
  end
end
