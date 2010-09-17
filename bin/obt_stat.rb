# this file is required when run_obt_stat.rb is run directly and not
# through the Gem generated stub installed in the path
require "iconv"

path = File.expand_path(File.dirname(__FILE__))

require path + "/../lib/writers"
require path + "/../lib/obno_stubs"
require path + "/../lib/obno_text"
require path + "/../lib/lemma_model"
require path + "/../lib/disambiguation_unit"
require path + "/../lib/disambiguation_context"
require path + "/../lib/disambiguator"
require path + "/../lib/evaluator"
require path + "/../lib/trace_logger"
