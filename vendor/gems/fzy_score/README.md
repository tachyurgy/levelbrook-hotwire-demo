# fzy_score

A tiny, dependency-free Ruby port of the [fzy](https://github.com/jhawthorn/fzy)
fuzzy-matching **scoring** algorithm — the same family of algorithm used by
[fzf](https://github.com/junegunn/fzf) and [fzf-for-js](https://github.com/ajitid/fzf-for-js).

Unlike Ruby's existing fuzzy gems (which solve *record linkage* with
Levenshtein/Dice/Jaro, or only answer the boolean "does it match?"),
`fzy_score` returns **both a relevance score and the matched character
positions** — exactly what you need to build:

- a command palette / quick-open
- an autocomplete dropdown
- a CLI picker with highlighted matches

It's pure Ruby, has zero runtime dependencies, and ports fzy's published
scoring constants verbatim so ranking matches the reference tool.

## Installation

```ruby
# Gemfile
gem "fzy_score"
```

```sh
gem install fzy_score
```

## Usage

### Score a single candidate

```ruby
require "fzy_score"

FzyScore.score("amf", "app/models/foo.rb")  # => 3.58 (higher is better)
FzyScore.score("zzz", "app/models/foo.rb")  # => -Infinity (no match)
FzyScore.score("abc", "abc")                # => Infinity (exact match)
```

### Get matched positions for highlighting

```ruby
m = FzyScore.match("amu", "app/models/user.rb")
m.score       # => Float
m.positions   # => [0, 4, 11]   indices into the haystack to highlight
m.matched?    # => true

# Highlight in a terminal:
def highlight(haystack, positions)
  set = positions.to_set
  haystack.each_char.with_index.map { |c, i| set.include?(i) ? "\e[33m#{c}\e[0m" : c }.join
end
puts highlight("app/models/user.rb", m.positions)
```

### Filter and rank a list (best first)

```ruby
files = ["spec/match_spec.rb", "src/match.rb", "README.md"]

FzyScore.filter("srcmatch", files)
# => [["src/match.rb", 6.97, nil]]   (non-matches dropped, sorted best-first)

# Want positions too?
FzyScore.filter("srcmatch", files, positions: true)
# => [["src/match.rb", 6.97, [0,1,2,4,5,6,7,8]]]

# Filtering objects? Pass a key extractor — the original object comes back.
people = [{ name: "Alice" }, { name: "Bob" }, { name: "Albert" }]
FzyScore.filter("al", people, key: ->(p) { p[:name] })
# => [[{name: "Albert"}, ...], [{name: "Alice"}, ...]]
```

### Cheap pre-filter

If you only need to know *whether* something matches (no scoring), use the
O(n) predicate:

```ruby
FzyScore.match?("amf", "app/models/foo.rb")  # => true
```

`filter` already uses this internally to skip the DP for non-matches.

## How scoring works

`fzy_score` implements fzy's modified Smith–Waterman dynamic program. Matches
earn bonuses for landing at "good" places and pay small penalties for gaps:

| Situation | Bonus / penalty |
|---|---|
| Consecutive characters | `+1.0` |
| First char after `/` (path component) | `+0.9` |
| First char after `-`, `_`, space (word start) | `+0.8` |
| Uppercase after lowercase (camelCase) | `+0.7` |
| First char after `.` (file extension) | `+0.6` |
| Leading / trailing gap | `-0.005` per char |
| Inner gap | `-0.01` per char |

An exact (case-insensitive) match returns `Float::INFINITY`; a non-match
returns `-Float::INFINITY` so it sorts last. These are the exact constants
from fzy's `config.def.h`.

## Comparison with other Ruby gems

| Gem | What it does | Returns a score? | Returns positions? |
|---|---|---|---|
| `fuzzy_match`, `amatch` | record linkage (Levenshtein/Dice/Jaro) | similarity | no |
| `fuzzyfinder` | boolean filter | no | no |
| **`fzy_score`** | **fzf/fzy-style ranking** | **yes** | **yes** |

## Development

```sh
bundle install
bundle exec rake test
```

## License

MIT © Levelbrook Consulting. See [LICENSE](LICENSE).

The scoring algorithm and constants are ported from
[jhawthorn/fzy](https://github.com/jhawthorn/fzy) (MIT).
