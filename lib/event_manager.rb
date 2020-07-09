require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

#@param zipcode[String]
def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5,"0")[0..4]
end

#@param phone[String]
def clean_phone(phone)
    phone.tr!('^a-zA-Z0-9','')
    
    if phone.length == 10
        phone
    elsif phone.length == 1 && phone[0] == '1'
        phone[1..phone.length]
    else
        'Invalid phone'
    end
end

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody','legislatorLowerBody']
        ).officials
    rescue
        "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
    end
end

def save_thank_you_letter(id,form_letter)
    Dir.mkdir("output") unless Dir.exist? "output"

    filename = "output/thanks_#{id}.html"

    File.open(filename,'w') do |file|
        file.puts form_letter
    end
end

puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

hour_array = []

day_of_week_array = []

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    
    zipcode = clean_zipcode(row[:zipcode])

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    phone_number = clean_phone(row[:homephone])

    # @type [String]
    date = row[:regdate]
    new_date = DateTime.strptime(date,'%m/%d/%Y %H:%M')
    hour_array.push new_date.hour
    day_of_week_array.push new_date.wday

    save_thank_you_letter(id,form_letter)
end

counts = Hash.new 0
hour_array.each do |hour|
    counts[hour] += 1
end

puts "Best hour #{counts.max_by{|k,v| v}}"

day = Hash.new 0
day_of_week_array.each do |hour|
    day[hour] += 1
end

p day

puts "Best day of the week #{day.max_by{|k,v| v}}"