require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.to_s.gsub(/[^0-9]/, '')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number.start_with?('1')
    phone_number[1..]
  else
    'Invalid phone number'
  end
end

def clean_date(reg_date)
  date = Date.strptime(reg_date, '%m/%d/%y %H:%M')
  date.strftime('%m/%d/%Y')
end

def clean_time(reg_date)
  # input: 11/12/2013 08:43
  # output: 08:43
  time = Time.strptime(reg_date, '%m/%d/%y %H:%M')
  time.strftime('%H:%M')
end

def clean_day(reg_date)
  # output: Monday
  # input: 11/12/2013 08:43
  day = Date.strptime(reg_date, '%m/%d/%y %H:%M')
  day.strftime('%A')
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  FileUtils.mkdir_p('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone_number(row[:homephone])
  date = clean_date(row[:regdate])
  time = clean_time(row[:regdate])
  day = clean_day(row[:regdate])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
