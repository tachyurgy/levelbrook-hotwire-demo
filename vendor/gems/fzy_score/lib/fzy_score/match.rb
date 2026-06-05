# frozen_string_literal: true

module FzyScore
  # Result of a scored fuzzy match.
  #
  # +score+    Float relevance score. Higher is better. {SCORE_MAX} for an
  #            exact (case-insensitive) match, {SCORE_MIN} for no match / empty
  #            needle / oversized candidate.
  # +positions+ Array<Integer> of the indices in +haystack+ that the needle
  #            matched, suitable for highlighting. +nil+ unless positions were
  #            requested.
  Match = Struct.new(:score, :positions) do
    # @return [Boolean] true when the candidate actually matched.
    def matched?
      score > SCORE_MIN
    end
  end
end
