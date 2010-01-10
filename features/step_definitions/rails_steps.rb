Given /^a Rails application "(.*?)"$/ do |name|
  system 'rails', name, '--quiet'
end
