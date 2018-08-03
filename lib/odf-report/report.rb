module ODFReport

class Report
  include Images

  def initialize(template_name, &block)

    @file = ODFReport::File.new(template_name)

    @texts = []
    @fields = []
    @tables = []
    @images = {}
    @new_images = []  # DP: images that are added in tables
    @image_names_replacements = {}
    @sections = []

    yield(self)

  end

  def add_field(field_tag, value='')
    opts = {:name => field_tag, :value => value}
    field = Field.new(opts)
    @fields << field
  end

  def add_text(field_tag, value='')
    opts = {:name => field_tag, :value => value}
    text = Text.new(opts)
    @texts << text
  end

  def add_table(table_name, collection, opts={})
    opts.merge!(:name => table_name, :collection => collection)
    tab = Table.new(opts)
    @tables << tab

    yield(tab)
  end

  def add_section(section_name, collection, opts={})
    opts.merge!(:name => section_name, :collection => collection)
    sec = Section.new(opts)
    @sections << sec

    yield(sec)
  end

  def add_image(name, path)
    @images[name] = path
  end

  def generate(dest = nil)

    @file.update_content do |file|

      file.update_files('content.xml', 'styles.xml', 'META-INF/manifest.xml') do |entry_name, txt|
        puts entry_name.inspect.red
        if entry_name.include? "manifest.xml"
          parse_document(txt) do |doc|
            process_additional_images(doc)
          end
          next
        end

        parse_document(txt) do |doc|

          @sections.each { |s| s.replace!(doc) }
          @tables.each do |t|
            t.replace! doc
          end

          @texts.each    { |t| t.replace!(doc) }
          @fields.each do |f|
            f.replace! doc
          end

          find_image_name_matches(doc)
          avoid_duplicate_image_names(doc)

        end

      end

      replace_images(file)

    end

    if dest
      ::File.open(dest, "wb") {|f| f.write(@file.data) }
    else
      @file.data
    end

  end

private

  def parse_document(txt)
    doc = Nokogiri::XML(txt)
    yield doc
    txt.replace(doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML))
  end


  def process_additional_images(doc)
     puts @new_images.inspect.magenta
     @new_images.each do |image_name|
       #path = @images[image_name]
       node = doc.xpath("//manifest:manifest").first
       # add the newly loaded image to the document manifest
       node.add_child "<manifest:file-entry manifest:full-path='#{image_name}' manifest:media-type='image/svg+xml'/>"
     end
  end

end

end
