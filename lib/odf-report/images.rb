module ODFReport

  module Images

    IMAGE_DIR_NAME = "Pictures"

    def find_image_name_matches(content)

      ##
      # DP: dynamic signature tags for embedding ink style svg signatures from signature_pad.js
      # limitations:  the size of the signature is fixed at 1.5in wide.
      # the signature tag must begin with the prefix:  SIGNATURE_
      content.xpath("//text:p[text()[starts-with(., 'SIGNATURE_')]]").each do |node|
        tag_name = node.text
        href = "Pictures/" + tag_name + ".svg"
        ink = "<text:p text:style-name='Standard'><draw:frame draw:style-name='signature_frame' draw:name='#{tag_name}' text:anchor-type='as-char' svg:width='1.75in' svg:height='0.37in' draw:z-index='0'><draw:image xlink:href='#{href}' xlink:type='simple' xlink:show='embed' xlink:actuate='onLoad'/></draw:frame></text:p>"
        node.replace ink
        @new_images << href
      end

      ## same for text:span inline text tags
      content.xpath("//text:span[text()[starts-with(., 'SIGNATURE_')]]").each do |node|
        tag_name = node.text
        href = "Pictures/" + tag_name + ".svg"

        # TODO: this style needs to be applied to the signatures to get them to sit on the baseline
        # style = " style:vertical-pos='middle' style:vertical-rel='baseline' "

        ink = "<text:span text:style-name='Standard'><draw:frame draw:style-name='signature_frame' draw:name='#{tag_name}' text:anchor-type='as-char' svg:width='1.75in' svg:height='0.37in' draw:z-index='0'><draw:image xlink:href='#{href}' xlink:type='simple' xlink:show='embed' xlink:actuate='onLoad'/></draw:frame></text:span>"
        node.replace ink
        @new_images << href
      end


      @images.each_pair do |image_name, path|
        if node = content.xpath("//draw:frame[@draw:name='#{image_name}']/draw:image").first
          placeholder_path = node.attribute('href').value
          @image_names_replacements[path] = ::File.join(IMAGE_DIR_NAME, ::File.basename(placeholder_path))
        end
      end
    end

    def replace_images(file)

      return if @images.empty?

      @image_names_replacements.each_pair do |path, template_image|
        file.output_stream.put_next_entry(template_image)
        file.output_stream.write ::File.read(path)
      end

    end # replace_images

    # newer versions of LibreOffice can't open files with duplicates image names
    def avoid_duplicate_image_names(content)

      nodes = content.xpath("//draw:frame[@draw:name]")

      nodes.each_with_index do |node, i|
        node.attribute('name').value = "pic_#{i}"
      end

    end

  end

end
