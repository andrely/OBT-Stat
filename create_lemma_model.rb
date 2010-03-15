#!/opt/local/bin/ruby

require 'disamb-proto'
require 'lemma_model'

if __FILE__ == $0
  lm = LemmaModel.new
  lm.create_lemma_model $stdin
  lm.write_lemma_model $stdout
end
