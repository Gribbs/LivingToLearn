require "prawn"
require "prawn/layout"
require "prawn/table"
require "prawn/measurement_extensions"

class Document::Reports::CcOverview
  cattr_accessor :page_number
  cattr_accessor :line_number

  extend DocumentFilesBase

  def self.report_filename()
    "#{self.filename_base}.report.pdf"
  end

####

  def self.physical_report_filename()
    File.join(self.physical_directory, self.report_filename() )
  end

###

  def self.public_report_filename()
    File.join(self.public_directory, self.report_filename() )
  end

###############
# Report
###############

  def self.filename_base
    'CcOverview'
  end

  def self.include?(object)
    return false if object.nil?
    return false if object.description == 'none'
    return true
  end

  def self.get_data
    harray = []
    self.curriculum_class.get_objects{ |c_object|
      next if !self.include?(c_object)
      harray << {
        :object => c_object,
        :level => Curriculum::Root.level_of(c_object)
      }
    }
    return harray
  end

  def self.report_line_for(c_object_hash)
    c_object_hash[:object].report_line(0).join('')
  end

  def self.indent_string(indent=0)
    indent_string = ""; indent.times{ indent_string << ' ' }
    return indent_string
  end

  def self.config
  end

  def self.report_pdf()
    self.config
    Prawn::Document.generate(
      self.physical_report_filename,
      #File.join(Rails.root,'report'),
      :page_size => "A3", :page_layout => :portrait, :margin => 0
    ) do |pdf|
      p "See #{self.physical_report_filename}"
      item_number = 1
      pdf.padded_box 10.mm do
        pdf.move_down(10.mm)
        items = []
        c_object_hashs = self.get_data
        if c_object_hashs.length == 0
          p "No Data Found!"
          break
        end
        c_object_hashs.each { |c_object_hash|
          object = c_object_hash[:object]
          level = c_object_hash[:level]
          r = [
            object.full_code,
            object.report_classname,
            object.report_by_grade,
            "#{object.report_description}"
          ]
          item_number += 1
          items << r
        }

        pdf.table items,
          :position   => :center,
          :border_style => :underline_header,
          :row_colors => ["FFFFFF","DDDDDD"],
          :headers => ["Code", "Standard Level", "By Grade", "Description"],
          :column_widths => { 0 => 140, 1 => 80, 2 => 50, 3 => 400 },
          :align => { 0 => :left, 1 => :left, 2 => :center, 3 => :left },
          :align_headers => { 0 => :left, 2 => :left, 3 => :center }
      end

      pdf.page_count.times do |i|
        page_num = i+1
        pdf.go_to_page(page_num)
        if page_num == 1
          # header of first page
          pdf.text_box "#{self.filename_base}", :at => [30.mm, 410.mm], :size => 18
          #image "logo.png", :at => [12.mm,(297-15.78).mm]
        else
          # header 2..n
          pdf.text_box "#{self.filename_base} page #{page_num} ", :at => [30.mm, 415.mm], :size => 12
        end
      end

    end
    return
  end

end

