#!/opt/local/bin/ruby

require 'disamb-proto'
require 'lemma_model'

if __FILE__ == $0
  lm = LemmaModel.new(nil)
  
  text = Text.new
  OBNOText.parse text, $stdin
  
  lm.create_lemma_model(text)

  lm.write_lemma_model($stdout)
end
