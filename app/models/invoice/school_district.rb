class Invoice::SchoolDistrict < ActiveRecord::Base

  set_table_name :invoice_school_districts

  def self.csv_headers
    self.columns.map{ |c| c.name}.join(',')
  end

  def csv_line
    self.class.columns.map{ |c| self.send(c.name.to_sym) }.join(',')
  end

  def self.erb_template_filename
    File.join(RAILS_ROOT,'app','views','invoices','school_district.html')
  end

  def invoice_html
    require 'erb'
    template_text= File.new(self.class.erb_template_filename,'r').read
    template_text.gsub!('&lt;','<');
    template_text.gsub!('&gt;','>');
    template = ERB.new( template_text )
    return template.result( binding )
  end

  def self.create_for(client_hash,month,year)
    h = client_hash.invoice_for(month,year)
    i = self.create(h)
    return i
  end

end
