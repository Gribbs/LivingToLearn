namespace :letter do

  desc "do"
  task :do => :environment do
    Document::Letter::Base.print({
      :first_name => "fn",
      :last_name => "ln",
      :address_line_1 => "al1",
      :address_line_2 => "al2",
      :city => "city",
      :state => "s",
      :zip => "z"
    })
  end

  desc "wbc"
  task :wbc => :environment do
    client = Person::Client.find_by_client_id(218.0)
    Document::Letter::WoodburyContract.print_for(client,'letter.pdf')
  end

  namespace :appointments do

    desc "SES Students"
    task :ses_now => :environment do
      Government::SchoolDistrict.all_appointment_letters(DateTime.now)
    end

    desc "SES Students"
    task :ses_yesterday => :environment do
      Government::SchoolDistrict.all_appointment_letters(DateTime.now-1.day)
    end

  end

end
