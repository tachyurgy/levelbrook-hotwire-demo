# frozen_string_literal: true

require_relative "lib/fzy_score/version"

Gem::Specification.new do |spec|
  spec.name = "fzy_score"
  spec.version = FzyScore::VERSION
  spec.authors = ["Levelbrook Team"]
  spec.email = ["levelbrookteam@gmail.com"]

  spec.summary = "Faithful Ruby port of the fzy/fzf fuzzy-matching scoring algorithm."
  spec.description = <<~DESC.strip
    A tiny, dependency-free fuzzy matcher that returns both a relevance score and the
    matched character positions (for highlighting) — the same algorithm family used by
    fzy, fzf, and fzf-for-js. Unlike Ruby's record-linkage fuzzy gems, fzy_score is built
    for command palettes, quick-open, autocomplete, and CLI pickers.
  DESC
  spec.homepage = "https://consulting.levelbrook.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tachyurgy/fzy_score"
  spec.metadata["changelog_uri"] = "https://github.com/tachyurgy/fzy_score/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*.rb",
    "README.md",
    "CHANGELOG.md",
    "LICENSE"
  ]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
