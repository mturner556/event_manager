require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislator_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def format_phone_number(phone_number)
  if phone_number.length > 10 && phone_number[0] == '1'
    phone_number.slice!(0)
    phone_number.insert(3, '-').insert(7, '-')
  elsif phone_number.length < 10 || phone_number.length > 11
    phone_number = 'Invalid phone number.'
  else
    phone_number.insert(3, '-').insert(7, '-')
  end

  phone_number
end

def hour_of_day(time)
  if time == 12
    "#{time} PM"
  elsif time > 12
    "#{time - 12} PM"
  elsif time == 0
    "#{time + 12} AM"
  else
    "#{time} AM"
  end
end

def day_of_week(date)
  if date == 0
    date = 'Sunday'
  elsif date == 1
    date = 'Monday'
  elsif date == 2
    date = 'Tuesday'
  elsif date == 3
    date = 'Wednesday'
  elsif date == 4
    date = 'Thursday'
  elsif date == 5
    date = 'Friday'
  else
    date = 'Satuday'
  end
end

puts 'Event Manager Initialized!'

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
  legislators = legislator_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  phone_number = row[:homephone].scan(/\d+/).join('')
  time = Time.parse(row[1].split(' ')[1]).hour
  date = Date.strptime(row[1], "%m/%d/%Y").wday

  puts "#{format_phone_number(phone_number)}, #{hour_of_day(time)}, #{day_of_week(date)}"
end
