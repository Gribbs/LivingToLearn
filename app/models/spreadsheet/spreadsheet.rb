require "roo"

class Spreadsheet::Spreadsheet

  cattr_accessor :headers
  cattr_accessor :column_header_hash

  cattr_accessor :filename
  cattr_accessor :spreadsheet

  cattr_accessor :raw_column_key
  cattr_accessor :column_key

  cattr_accessor :lookup_cache

  cattr_accessor :record_hash_array

  cattr_accessor :connected_object_attr

#############
# Reflection of Spreadsheet in Object
#############

  def self.connected_object
    return self.connected_object_attr
  end

###################
# Cache Used when SQL not
###################

  def self.cache_name
    self.to_s.split('::').last.underscore
  end

#############
# Directory
#############

  def ss_backup_directory
    File.join(ENV['ARCHIVED_COMMUNICATIONS_DIR'],'spreadsheet_backup')
  end

  def cache_directory
    File.join(self.ss_backup_directory,self.class.cache_name)
  end

############
# Files
#############

  def self.timestamp
    Time.now.to_s.gsub('-','').gsub(':','_').gsub(' ','__')
  end

###################
#
###################

   def self.cache_dump
     Rails.cache.read(self.cache_name)
   end

   def self.cache_load
     ss= self.new
     ss.class.filename= ss.google_path
     record_hash_array= ss.class.load_record_hash_array
     Rails.cache.write(ss.class.cache_name, record_hash_array)
     ss.cache_snapshot(record_hash_array)
   end

   def cache_snapshot(record_hash_array)
     Dir.mkdir(self.ss_backup_directory) if !File.exists?(self.ss_backup_directory)
     Dir.mkdir(self.cache_directory) if !File.exists?(self.cache_directory)
     #filename= File.join(self.cache_directory,"as_of__#{self.class.timestamp}.json")
     #File.open( filename,'w+').write(record_hash_array.to_json)
     filename= File.join(self.cache_directory,"as_of__#{self.class.timestamp}.xml")
     File.open( filename,'w+').write(record_hash_array.to_xml)
   end

#############
#
#############

  def self.purge
  end

#############
# Validate
#############
  def self.n_actual_to_sym(n_actual)
    n_actual.underscore.sub(/[\d]/){|s| "_#{s}"}.to_sym
  end

  def self.get_n_actual(actual)
    actual.strip.gsub('_','').gsub(' ','')
  end

  def self.header_match(actual)
    return false if actual.nil?
    n_actual= self.get_n_actual(actual)
    m = self.headers.include?(n_actual)
    if !m
      p "Mismatch of Header #{n_actual} in headers #{self.headers.inspect}"
    end
    return m
  end

  def self.validate_using_headers
    ok = true
    self.column_header_hash = {}
    headers.each_index{ |index|
      actual = self.spreadsheet.cell(1,index+1)
      next if actual.nil?
      expected = headers[index]
      if !header_match(actual)
        p "Not accepted: #{actual} because expected #{expected}"
        ok = false
      else
        n_actual = self.get_n_actual(actual)
        sym = self.n_actual_to_sym(n_actual)
        #self.column_header_hash[index]= self.get_n_actual(actual).underscore.to_sym
        self.column_header_hash[index]= sym
      end
    }
    return ok
  end

  def self.headers_from_columns( connected_object )
    return connected_object.columns.map{ |col| col.name.camelcase}
  end

  def self.check_headers
    ok = true

    if !self.connected_object
      p "All Spreadsheets must have connected Objects"
      return nil
    end

    self.headers = headers_from_columns( self.connected_object ) if self.connected_object.respond_to?(:columns)
    self.headers = self.connected_object.headers if !self.headers and !self.connected_object.headers.nil?
    if  self.headers then
      ok = self.validate_using_headers
    end

    return ok
  end

##################
#
###################
  def self.clean_row_hash(row_hash)
    row_hash
  end

  def self.use_row?(row_hash)
    true
  end

  def self.load_record_hash_array
    self.connected_object.prepare_table_for_stores
    self.record_hash_array = []
    self.load_records{ |rh|
      clean_row = self.clean_row_hash(rh)
      self.connected_object.store_row_hash( clean_row )
      record_hash_array<< clean_row if use_row?( clean_row )
    }
    self.record_hash_array
  end

  def self.key_for_header(index)
    column_header_hash[index]
  end

  def self.load_records(&block)
    self.column_key = {}
    self.each_header{ |column,content|
    }
    return if !block_given?
    self.each_row { |spreadsheet,row|
      row_hash = {}
      headers.each_index{ |i|
        val= spreadsheet.cell( row , i+1 )
        val.strip! if !val.nil? and val.is_a? String
        k = key_for_header( i )
        row_hash[ k ]= val if k
      }
      putc('.')
      end_of_list= ( row_hash.values.compact.length == 0 )
      yield( row_hash ) if !end_of_list
      end_of_list
    }
  end

  def self.load_record_file(filename)
    self.spreadsheet = nil
    self.filename = filename
    self.load_records()
    self.spreadsheet
  end

  def self.csv_record_file(spreadsheet_filename,csv_filename)
    self.spreadsheet = nil
    self.filename = spreadsheet_filename
    self.open
    if self.spreadsheet.nil?
      p "spreadsheet not found!"
    else
      self.spreadsheet.to_csv(csv_filename)
    end
  end

  def self.open
    if self.spreadsheet.nil?
      name,ext= self.filename.split('.')
      if ext == 'ods'
          self.spreadsheet = Openoffice.new(self.filename) 
      end
      if ext == 'xls'
        self.spreadsheet = Excel.new(self.filename)
      end
      if ext == 'gxls'
        file= GoogleApi::Document.find(self.filename)
        if file
          key = /spreadsheet:(.*)/.match(file.id)[1]
          self.spreadsheet = Google.new(key)
        else
          p "File #{self.filename} not found"
        end
      end
    end
    ok = self.check_headers
    if !ok
      p "Spreadsheet Header mismatch in #{self.filename}"
    end
    self.spreadsheet
  end

  def self.close
    self.spreadsheet = nil
  end

  def self.normalize_header(h)
    r = if h.nil? then nil else h.gsub('_','').gsub(' ','') end
    return r
  end

  def self.each_header(&block)
    if (s = self.open)
      column = 1
      self.raw_column_key = {}
      while not( content = normalize_header(s.cell(1,column)) ).nil?
        yield(column,content) if block_given?
        raw_column_key[column] = content
        column += 1
      end
    else
      p "Could not open spreadshet #{self.filename}"
    end
  end

  def self.convert_header()
    self.column_key = {}
    self.raw_column_key.each_pair{ |col,header|
      self.column_key[col] = header.gsub(' ','').underscore
    }
  end

  def self.each_row(&block)
      row = 2
      end_of_list = false
      while not( end_of_list )
        row_content = {}
        end_of_list= yield( self.spreadsheet, row )
        row += 1
      end
  end

  def self.each_record(&block)
      row = 2
      end_of_list = false
      while not( end_of_list )
        row_content = {}
        end_of_list = true
        self.column_key.each_pair{ |col,field|
          row_content[field] = ( content = self.spreadsheet.cell(row,col) )
          end_of_list =  false if end_of_list and !content.nil?
        }
        yield(row,row_content)  if not(end_of_list)
        row += 1
      end
  end

  def google_filename
    fn= self.class.to_s.split('::')[1]
    "#{fn}.gxls"
  end

  def self.clean_row_hash(row_hash)
    return row_hash if row_hash[:zip].nil?
    raw= row_hash[:zip]
    row_hash[:zip]= if raw.is_a? Integer then
      "_%.5i" % raw
    elsif raw.is_a? Float then
      "_%.5i" % raw.to_i
    else
      raw.to_s
    end
    row_hash
  end

########################
# Better I/F
########################

  def self.get_spreadsheet( filename )
    self.spreadsheet= nil
    self.filename= filename
    self.open
    return self.spreadsheet
  end

  def initialize(params)
  end

  def self.get_hash_array( filename )
    self.spreadsheet= nil
    self.filename= filename
    ss_object= self.new({})
    load_record_hash_array
    return ss_object.class.record_hash_array
  end

  def self.get_records( filename )
    self.spreadsheet= nil
    self.filename= filename
    ss_object= self.new({})
    load_record_hash_array
    return ss_object.class.record_hash_array
  end

  def self.store(filename)
    hash_array= get_hash_array( filename )
    hash_array.each{ |hash|
      self.store_hash(filename,hash)
    }
    self.identity_class.from_source(filename)
  end

################
#
################

  def self.test_google_ss
    return self.new
  end

###################
#
####################

  def self.get_spreadsheet_from_google(name_array)
    self.filename = "#{File.join(name_array)}.gxls"
    spreadsheet = self.open
  end

  def self.get_symbolized_headers_from_google_spreadsheet(name_array)
    spreadsheet = self.get_spreadsheet_from_google(name_array)
    index = 0
    ok = true
    raw_headers = []
    while ok do
      h = spreadsheet.cell(1,index+1)
      ok = (h and h.length > 0)
      raw_headers << h if ok
      index += 1
    end
    normalized_headers = raw_headers.map{ |h| Spreadsheet::Spreadsheet.normalize_header(h) }
    symbolized_headers = normalized_headers.map{ |h| Spreadsheet::Spreadsheet.n_actual_to_sym(h) }
    return symbolized_headers
  end

  def self.get_table_name_from_google_spreadsheet(name_array)
    r = ['spreadsheet']
    r<< name_array.map{ |n| n.underscore }
    r.flatten!
    return r.join('__')
  end

  def self.get_migration_from_google_spreadsheet(name_array)
    table_name = self.get_table_name_from_google_spreadsheet(name_array)
    migration = []
    migration<<(top_line =
      "create_table \"#{table_name}\", :force => true do |t|" )
    self.get_symbolized_headers_from_google_spreadsheet(name_array).each{ |symbolized_header|
       migration<< "t.string   :#{symbolized_header}"
    }
    migration << (bottom__line = "end")
    return migration
  end

  def self.get_class_name_from_google_spreadsheet(name_array)
    rs = ["Spreadsheet"]
    rs << name_array[0..-2]
    rs << name_array[-1].singularize
    rs.flatten!
    result=rs.join("::")
    return [result]
  end

  def self.get_class_def_from_google_spreadsheet(name_array)
    class_def = []
    class_def <<
      "class #{get_class_name_from_google_spreadsheet(name_array)} < Spreadsheet::SpreadsheetTable"
    class_def <<
      "set_table_name (#{self.get_table_name_from_google_spreadsheet(name_array)})"
    class_def <<
      "end"
    return class_def
  end

  def self.get_records_from_google_spreadsheet(spreadsheet_table_class)
    self.connected_object_attr = spreadsheet_table_class
    self.spreadsheet = self.get_spreadsheet_from_google(spreadsheet_table_class.name_array)
    spreadsheet_table_class.delete_all
    self.load_records{ |rh|
      spreadsheet_table_class.create( rh )
    }
    return spreadsheet_table_class.all
  end

end
