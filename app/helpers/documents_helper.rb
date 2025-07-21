module DocumentsHelper
  def parse_diff_data(diff_data)
    return [] unless diff_data.present?
    
    begin
      JSON.parse(diff_data)
    rescue JSON::ParserError
      parse_git_diff(diff_data)
    end
  end

  def parse_git_diff(diff_text)
    return [] unless diff_text.present?
    
    files = []
    current_file = nil
    current_hunk = nil
    old_line_no = 0
    new_line_no = 0
    
    diff_text.lines.each do |line|
      line = line.chomp
      
      case line
      when /^diff --git a\/(.*) b\/(.*)/
        # New file diff
        files << current_file if current_file
        current_file = {
          path: $1,
          hunks: []
        }
      when /^--- (.*)/, /^\+\+\+ (.*)/
        # File path info, already handled above
        next
      when /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)?/
        # Hunk header
        if current_file
          old_line_no = $1.to_i
          new_line_no = $3.to_i
          current_hunk = {
            old_start: old_line_no,
            old_lines: ($2 || 1).to_i,
            new_start: new_line_no,
            new_lines: ($4 || 1).to_i,
            header: $5&.strip,
            lines: []
          }
          current_file[:hunks] << current_hunk
        end
      when /^[\+\-\s].*/
        # Diff line
        if current_hunk
          type = case line[0]
                 when '+'
                   'addition'
                 when '-'
                   'deletion'
                 else
                   'context'
                 end
          
          line_data = {
            type: type,
            content: line[1..-1] || '',
            number_old: nil,
            number_new: nil
          }
          
          case type
          when 'addition'
            line_data[:number_new] = new_line_no
            new_line_no += 1
          when 'deletion'
            line_data[:number_old] = old_line_no
            old_line_no += 1
          when 'context'
            line_data[:number_old] = old_line_no
            line_data[:number_new] = new_line_no
            old_line_no += 1
            new_line_no += 1
          end
          
          current_hunk[:lines] << line_data
        end
      end
    end
    
    files << current_file if current_file
    files
  end

  def render_diff_file(file_data)
    content_tag :div, class: "diff-file" do
      file_header(file_data) + 
      file_data[:hunks].map { |hunk| render_diff_hunk(hunk) }.join.html_safe
    end
  end

  def file_header(file_data)
    content_tag :div, class: "diff-file-header" do
      content_tag :span, file_data[:path], class: "file-path"
    end
  end

  def render_diff_hunk(hunk_data)
    content_tag :div, class: "diff-hunk" do
      hunk_header(hunk_data) +
      content_tag(:table, class: "diff-table") do
        hunk_data[:lines].map { |line| render_diff_line(line) }.join.html_safe
      end
    end
  end

  def hunk_header(hunk_data)
    header_text = "@@ -#{hunk_data[:old_start]},#{hunk_data[:old_lines]} +#{hunk_data[:new_start]},#{hunk_data[:new_lines]} @@"
    header_text += " #{hunk_data[:header]}" if hunk_data[:header].present?
    
    content_tag :div, header_text, class: "hunk-header"
  end

  def render_diff_line(line_data)
    css_class = "diff-line diff-line-#{line_data[:type]}"
    
    content_tag :tr, class: css_class do
      old_line_number(line_data) +
      new_line_number(line_data) +
      line_content(line_data)
    end
  end

  def old_line_number(line_data)
    number = line_data[:number_old]
    content_tag :td, number, class: "line-number old-line-number"
  end

  def new_line_number(line_data)
    number = line_data[:number_new]
    content_tag :td, number, class: "line-number new-line-number"
  end

  def line_content(line_data)
    content = line_data[:content] || ''
    prefix = case line_data[:type]
             when 'addition'
               '+'
             when 'deletion'
               '-'
             else
               ' '
             end
    
    content_tag :td, class: "line-content" do
      content_tag(:span, prefix, class: "line-prefix") + 
      content_tag(:span, content, class: "line-text")
    end
  end
end
