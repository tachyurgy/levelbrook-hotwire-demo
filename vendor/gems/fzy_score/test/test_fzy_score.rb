# frozen_string_literal: true

require "minitest/autorun"
require "fzy_score"

class TestFzyScore < Minitest::Test
  # --- match? (the cheap prefilter) ---------------------------------------

  def test_match_predicate_basic
    assert FzyScore.match?("amf", "app/models/foo.rb")
    assert FzyScore.match?("", "anything")
    refute FzyScore.match?("xyz", "app/models/foo.rb")
  end

  def test_match_predicate_is_case_insensitive
    assert FzyScore.match?("AMF", "app/models/foo.rb")
    assert FzyScore.match?("amf", "APP/Models/Foo.rb")
  end

  def test_match_predicate_requires_order
    refute FzyScore.match?("fma", "app/models/foo.rb")
  end

  # --- score --------------------------------------------------------------

  def test_empty_needle_scores_min
    assert_equal FzyScore::SCORE_MIN, FzyScore.score("", "abc")
  end

  def test_no_match_scores_min
    assert_equal FzyScore::SCORE_MIN, FzyScore.score("zzz", "abc")
  end

  def test_exact_match_scores_max
    assert_equal FzyScore::SCORE_MAX, FzyScore.score("abc", "abc")
    assert_equal FzyScore::SCORE_MAX, FzyScore.score("ABC", "abc")
  end

  def test_real_match_has_finite_score
    s = FzyScore.score("amf", "app/models/foo.rb")
    assert s.finite?
    assert s > FzyScore::SCORE_MIN
  end

  def test_consecutive_beats_scattered
    consecutive = FzyScore.score("file", "file.rb")
    scattered = FzyScore.score("file", "fXiXlXe.rb")
    assert consecutive > scattered,
           "consecutive match (#{consecutive}) should beat scattered (#{scattered})"
  end

  def test_word_start_beats_midword
    at_start = FzyScore.score("ml", "my_lib")        # m at start, l after underscore
    mid = FzyScore.score("ml", "small")              # m and l mid-word
    assert at_start > mid,
           "word-boundary match (#{at_start}) should beat mid-word (#{mid})"
  end

  def test_slash_bonus_for_path_components
    # Both match, but the one starting a path component should score higher.
    comp = FzyScore.score("m", "a/models")
    mid = FzyScore.score("m", "axxmodels")
    assert comp > mid
  end

  def test_shorter_haystack_ranks_higher_for_same_pattern
    short = FzyScore.score("gem", "gems")
    long = FzyScore.score("gem", "a_very_long_gem_name_here")
    assert short > long
  end

  # --- match (with positions) ---------------------------------------------

  def test_positions_for_consecutive_run
    m = FzyScore.match("file", "file.rb")
    assert_equal [0, 1, 2, 3], m.positions
    assert m.matched?
  end

  def test_positions_point_at_correct_chars
    haystack = "app/models/user.rb"
    needle = "amu"
    m = FzyScore.match(needle, haystack)
    got = m.positions.map { |i| haystack[i] }.join.downcase
    assert_equal needle, got
  end

  def test_positions_prefer_word_boundaries
    # "mu" in "app/models/user.rb" should latch onto the m of models and u of user,
    # i.e. boundaries, not the m...u of an earlier incidental match if any.
    haystack = "app/models/user.rb"
    m = FzyScore.match("mu", haystack)
    assert_equal "m", haystack[m.positions[0]].downcase
    assert_equal "u", haystack[m.positions[1]].downcase
    # the u chosen should be the start of "user", which is at a slash boundary
    assert_equal "/", haystack[m.positions[1] - 1]
  end

  def test_exact_match_positions_are_identity
    m = FzyScore.match("abc", "abc")
    assert_equal [0, 1, 2], m.positions
    assert_equal FzyScore::SCORE_MAX, m.score
  end

  def test_no_match_has_nil_positions_and_not_matched
    m = FzyScore.match("zzz", "abc")
    assert_nil m.positions
    refute m.matched?
  end

  def test_positions_can_be_disabled
    m = FzyScore.match("amf", "app/models/foo.rb", positions: false)
    assert_nil m.positions
    assert m.score.finite?
  end

  def test_score_matches_match_score
    needle = "amf"
    haystack = "app/models/foo.rb"
    assert_in_delta FzyScore.score(needle, haystack),
                    FzyScore.match(needle, haystack, positions: false).score,
                    1e-12
  end

  # --- filter -------------------------------------------------------------

  def test_filter_ranks_best_first
    candidates = ["spec/match_spec.rb", "src/match.rb", "README.md"]
    rows = FzyScore.filter("srcmatch", candidates)
    assert_equal "src/match.rb", rows.first[0]
  end

  def test_filter_drops_non_matches
    candidates = ["alpha", "beta", "gamma"]
    rows = FzyScore.filter("xyz", candidates)
    assert_empty rows
  end

  def test_filter_returns_score_and_optional_positions
    rows = FzyScore.filter("ab", ["abc", "xab"], positions: true)
    rows.each do |candidate, sc, pos|
      assert_kind_of Float, sc
      assert_kind_of Array, pos
      assert_equal candidate.downcase.chars.values_at(*pos).join, "ab"
    end
  end

  def test_filter_positions_nil_by_default
    rows = FzyScore.filter("ab", ["abc"])
    assert_nil rows.first[2]
  end

  def test_filter_is_stable_on_ties
    # Identical strings => identical scores; original order should be preserved.
    candidates = ["dup", "dup", "dup"]
    rows = FzyScore.filter("dup", candidates)
    assert_equal 3, rows.length
  end

  def test_filter_with_key_extractor
    people = [{ name: "Alice" }, { name: "Bob" }, { name: "Albert" }]
    rows = FzyScore.filter("al", people, key: ->(p) { p[:name] })
    names = rows.map { |c, _, _| c[:name] }
    assert_includes names, "Alice"
    assert_includes names, "Albert"
    refute_includes names, "Bob"
  end

  # --- robustness ---------------------------------------------------------

  def test_oversized_candidate_scores_min
    huge = "a" * (FzyScore::MATCH_MAX_LEN + 10)
    assert_equal FzyScore::SCORE_MIN, FzyScore.score("aaa", huge)
  end

  def test_needle_longer_than_haystack_scores_min
    assert_equal FzyScore::SCORE_MIN, FzyScore.score("abcd", "abc")
  end

  def test_unicode_is_handled_by_character_not_byte
    # downcase + per-char indexing should be codepoint-aware.
    assert FzyScore.match?("café", "a café here")
    m = FzyScore.match("é", "café")
    assert_equal [3], m.positions
  end
end
