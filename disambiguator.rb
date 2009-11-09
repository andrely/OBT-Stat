class Disambiguator
  def initialize(text, hunpos_stream, evaluator)
    @text = text
    @hunpos_stream = hunpos_stream
    @evaluator = evaluator
  end

  def disambiguate
    @text.sentences.each do |s|
      s.words.each do |w|
        # not ambigious
        if w.tags.count == 1
          ob_tag = w.tags.first
          puts w.string + "\t" + ob_tag.clean_out_tag + "\t" + ob_tag.lemma
          @hunpos_stream.gets
          # ambigious
        else
          # get and parse line from hunpos process
          hun_line = @hunpos_stream.gets.strip
          hun_word, hun_tag = hun_line.split(/\s/)

          # fetch tags
          tags = w.tags.collect {|t| t.clean_out_tag}

          # sanity check on input position
          raise RuntimeError if hun_word != w.string

          # use hunpos tag if found, just take the first tag otherwise
          if tags.include? hun_tag
            $stderr.puts "ambiguity hunpos tag #{hun_tag} chosen"

            ob_tag = w.tag_by_string(hun_tag)

            raise RuntimeError if ob_tag.nil?

            puts w.string + "\t" + ob_tag.clean_out_tag + "\t" + ob_tag.lemma
          else
            $stderr.puts "ambiguity ob tag #{w.tags.first.clean_out_tag} chosen"

            ob_tag = w.tags.first

            puts w.string + "\t" + ob_tag.clean_out_tag + "\t" + ob_tag.lemma
          end
        end
      end
    end
  end
end