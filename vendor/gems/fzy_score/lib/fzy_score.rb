# frozen_string_literal: true

require_relative "fzy_score/version"
require_relative "fzy_score/match"

# FzyScore is a faithful, dependency-free Ruby port of the {https://github.com/jhawthorn/fzy
# fzy} fuzzy-matching scoring algorithm (the same family of algorithm used by
# {https://github.com/junegunn/fzf fzf} and {https://github.com/ajitid/fzf-for-js fzf-for-js}).
#
# Unlike Ruby's existing fuzzy gems (which do Levenshtein/Dice record linkage, or a
# boolean "does it match" filter), FzyScore returns BOTH a relevance *score* and the
# matched character *positions* — exactly what you need to build a command palette,
# quick-open, autocomplete, or CLI picker with highlighting.
#
# @example Quick scoring
#   FzyScore.score("amf", "app/models/foo.rb") # => Float
#
# @example Ranking candidates
#   FzyScore.filter("srcmtch", ["src/match.rb", "spec/match_spec.rb", "README.md"])
#   # => [["src/match.rb", <score>, [0,1,2,4,5,6,7]], ...]   (best first)
#
# @example Highlighting
#   m = FzyScore.match("mr", "app/models/user.rb", positions: true)
#   m.positions # => indices to highlight
module FzyScore
  # Scoring constants, taken verbatim from fzy's config.def.h so that ranking
  # matches the reference implementation.
  SCORE_GAP_LEADING      = -0.005
  SCORE_GAP_TRAILING     = -0.005
  SCORE_GAP_INNER        = -0.01
  SCORE_MATCH_CONSECUTIVE = 1.0
  SCORE_MATCH_SLASH      = 0.9
  SCORE_MATCH_WORD       = 0.8
  SCORE_MATCH_CAPITAL    = 0.7
  SCORE_MATCH_DOT        = 0.6

  SCORE_MAX = Float::INFINITY
  SCORE_MIN = -Float::INFINITY

  # Candidates longer than this are not scored with the full DP (treated as
  # SCORE_MIN), matching fzy's behaviour of not penalising the rest of the UI
  # for one unreasonably large entry.
  MATCH_MAX_LEN = 1024

  # Bonus awarded to a character based on the character that precedes it.
  # Mirrors fzy's bonus_states table.
  WORD_BREAK = { "-" => SCORE_MATCH_WORD, "_" => SCORE_MATCH_WORD, " " => SCORE_MATCH_WORD }.freeze

  module_function

  # Does +needle+ fuzzily match +haystack+ at all (case-insensitive, in order)?
  #
  # This is the cheap O(n) pre-filter; it does not compute a score.
  #
  # @param needle [String]
  # @param haystack [String]
  # @return [Boolean]
  def match?(needle, haystack)
    n = needle.downcase
    h = haystack.downcase
    j = 0
    n.each_char do |ch|
      j = h.index(ch, j)
      return false if j.nil?

      j += 1
    end
    true
  end

  # Score how well +needle+ matches +haystack+. Returns {SCORE_MIN} when there
  # is no match (so it sorts last). Higher is better.
  #
  # @param needle [String]
  # @param haystack [String]
  # @return [Float]
  def score(needle, haystack)
    do_match(needle, haystack, positions: false).score
  end

  # Score +needle+ against +haystack+ and (optionally) return the matched
  # positions for highlighting.
  #
  # @param needle [String]
  # @param haystack [String]
  # @param positions [Boolean] also compute the matched indices (slightly more work)
  # @return [FzyScore::Match]
  def match(needle, haystack, positions: true)
    do_match(needle, haystack, positions: positions)
  end

  # Filter and rank a list of candidates against +needle+, best first.
  #
  # Each returned row is +[candidate, score, positions]+. Candidates that do
  # not match are dropped. Sorting is stable on ties (preserves input order),
  # matching the intuition users expect from a picker.
  #
  # @param needle [String]
  # @param candidates [Array<#to_s>]
  # @param positions [Boolean] include matched positions in each row
  # @param key [Proc, nil] extract the string to match from each candidate
  # @return [Array<Array>] rows of [candidate, score, positions_or_nil]
  def filter(needle, candidates, positions: false, key: nil)
    rows = []
    candidates.each_with_index do |candidate, idx|
      str = key ? key.call(candidate) : candidate.to_s
      next unless match?(needle, str)

      m = do_match(needle, str, positions: positions)
      rows << [candidate, m.score, m.positions, idx]
    end
    # Stable sort: higher score first, original index breaks ties.
    rows.sort_by! { |row| [-row[1], row[3]] }
    rows.map { |candidate, sc, pos, _| [candidate, sc, pos] }
  end

  # --- internal -------------------------------------------------------------

  # @api private
  def do_match(needle, haystack, positions:)
    return Match.new(SCORE_MIN, nil) if needle.nil? || needle.empty?
    return Match.new(SCORE_MIN, nil) unless match?(needle, haystack)

    n = needle.length
    m = haystack.length

    if m > MATCH_MAX_LEN || n > m
      return Match.new(SCORE_MIN, nil)
    elsif n == m
      # Same length AND it matched => identical (case-insensitive).
      return Match.new(SCORE_MAX, positions ? (0...n).to_a : nil)
    end

    lower_needle = needle.downcase
    lower_haystack = haystack.downcase
    match_bonus = precompute_bonus(haystack)

    if positions
      compute_with_positions(lower_needle, lower_haystack, match_bonus, n, m)
    else
      Match.new(compute_score(lower_needle, lower_haystack, match_bonus, n, m), nil)
    end
  end

  # Per-position bonus based on the *preceding* character (word starts, slashes,
  # dots, camelCase transitions). The first character is treated as if preceded
  # by a slash, matching fzy.
  # @api private
  def precompute_bonus(haystack)
    bonus = Array.new(haystack.length, 0.0)
    last_ch = "/"
    haystack.each_char.with_index do |ch, i|
      bonus[i] = compute_bonus(last_ch, ch)
      last_ch = ch
    end
    bonus
  end

  # @api private
  def compute_bonus(last_ch, ch)
    # Bonus only applies to alphanumeric current characters.
    return 0.0 unless ch.match?(/[a-z0-9]/i)

    case last_ch
    when "/"
      SCORE_MATCH_SLASH
    when "-", "_", " "
      SCORE_MATCH_WORD
    when "."
      SCORE_MATCH_DOT
    else
      # camelCase: an uppercase current char after a lowercase previous char.
      if ch.match?(/[A-Z]/) && last_ch.match?(/[a-z]/)
        SCORE_MATCH_CAPITAL
      else
        0.0
      end
    end
  end

  # Score-only DP. Two rolling rows (D and M), matching fzy's match().
  # @api private
  def compute_score(needle, haystack, match_bonus, n, m)
    d_last = Array.new(m, SCORE_MIN)
    m_last = Array.new(m, SCORE_MIN)
    d_curr = Array.new(m, SCORE_MIN)
    m_curr = Array.new(m, SCORE_MIN)

    n.times do |i|
      match_row(i, n, needle, haystack, match_bonus, m, d_curr, m_curr, d_last, m_last)
      d_curr, d_last = d_last, d_curr
      m_curr, m_last = m_last, m_curr
    end

    # After the swap, the last computed row is in *_last.
    m_last[m - 1]
  end

  # Full DP keeping every row so positions can be backtracked. Mirrors fzy's
  # match_positions().
  # @api private
  def compute_with_positions(needle, haystack, match_bonus, n, m)
    d = Array.new(n) { Array.new(m, SCORE_MIN) }
    mm = Array.new(n) { Array.new(m, SCORE_MIN) }

    match_row(0, n, needle, haystack, match_bonus, m, d[0], mm[0], d[0], mm[0])
    (1...n).each do |i|
      match_row(i, n, needle, haystack, match_bonus, m, d[i], mm[i], d[i - 1], mm[i - 1])
    end

    positions = Array.new(n, 0)
    match_required = false
    j = m - 1
    i = n - 1
    while i >= 0
      while j >= 0
        if d[i][j] != SCORE_MIN && (match_required || d[i][j] == mm[i][j])
          match_required =
            i.positive? && j.positive? &&
            mm[i][j] == d[i - 1][j - 1] + SCORE_MATCH_CONSECUTIVE
          positions[i] = j
          j -= 1
          break
        end
        j -= 1
      end
      i -= 1
    end

    Match.new(mm[n - 1][m - 1], positions)
  end

  # Compute one row of the DP. Faithful translation of fzy's match_row().
  # @api private
  def match_row(i, n, needle, haystack, match_bonus, m, d_curr, m_curr, d_last, m_last)
    prev_score = SCORE_MIN
    gap_score = i == n - 1 ? SCORE_GAP_TRAILING : SCORE_GAP_INNER
    needle_ch = needle[i]

    j = 0
    while j < m
      if needle_ch == haystack[j]
        score = SCORE_MIN
        if i.zero?
          score = (j * SCORE_GAP_LEADING) + match_bonus[j]
        elsif j.positive?
          consecutive = d_last[j - 1] + SCORE_MATCH_CONSECUTIVE
          via_bonus = m_last[j - 1] + match_bonus[j]
          score = via_bonus > consecutive ? via_bonus : consecutive
        end
        d_curr[j] = score
        candidate = prev_score + gap_score
        m_curr[j] = prev_score = score > candidate ? score : candidate
      else
        d_curr[j] = SCORE_MIN
        m_curr[j] = prev_score = prev_score + gap_score
      end
      j += 1
    end
  end
end
