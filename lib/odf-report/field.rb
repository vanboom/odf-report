module ODFReport
  class Field
    include ActionView::Helpers::NumberHelper
    attr_accessor :name, :data_field, :value
    DELIMITERS = %w([ ])

    def initialize(opts, &block)
      @name = opts[:name]
      @data_field = opts[:data_field]
      @raw = opts[:raw]

      unless @value = opts[:value]

        if block_given?
          @block = block

        else
          @block = lambda { |item| self.extract_value(item) }
        end

      end

    end

    def replace!(content, data_item = nil)
      txt = content.inner_html

      val = get_value(data_item)
      sv = sanitize(val)
      # sub currency formats
      g1 = if to_placeholder.match( /price|cost|cogs|tax|total/i ) or val.class == "Money"
        txt.gsub!("$" + to_placeholder, number_to_currency(sv))
      end
      # sub the plain format
      g2 = txt.gsub!(to_placeholder, sv)
      if g1 or g2
        ##
        # Special handling allows us to inject raw ODT/XML into the document
        if @raw
          puts to_placeholder.to_s.red
          old_node = content.xpath("//text:p[contains(text(), \"#{to_placeholder}\")]").first
          if old_node
            old_node.replace val
          end
          old_node = content.xpath("//text:span[contains(text(), \"#{to_placeholder}\")]").first
          if old_node
            old_node.parent.replace val
          end
        else
          content.inner_html = txt
        end
      end
    end

    def get_value(data_item = nil)
      @value || @block.call(data_item) || ''
    end

    def extract_value(data_item)
      return unless data_item

      key = @data_field || @name

      if data_item.is_a?(Hash)
        data_item[key] || data_item[key.to_s.downcase] || data_item[key.to_s.upcase] || data_item[key.to_s.downcase.to_sym]

      elsif data_item.respond_to?(key.to_s.downcase.to_sym)
        data_item.send(key.to_s.downcase.to_sym)

      else
        raise "Can't find field [#{key}] in this #{data_item.class}"

      end

    end

    private

    def to_placeholder
      if DELIMITERS.is_a?(Array)
        "#{DELIMITERS[0]}#{@name.to_s.upcase}#{DELIMITERS[1]}"
      else
        "#{DELIMITERS}#{@name.to_s.upcase}#{DELIMITERS}"
      end
    end

    def sanitize(txt)
      txt = html_escape(txt)
      txt = odf_linebreak(txt)
      txt
    end

    HTML_ESCAPE = { '&' => '&amp;',  '>' => '&gt;',   '<' => '&lt;', '"' => '&quot;' }

    def html_escape(s)
      return "" unless s
      s.to_s.gsub(/[&"><]/) { |special| HTML_ESCAPE[special] }
    end

    def odf_linebreak(s)
      return "" unless s
      s.to_s.gsub("\n", "<text:line-break/>")
    end



  end
end
