require_relative 'bot'

require 'rubocop/rake_task'
RuboCop::RakeTask.new

REPOS = [
  'CocoaPods',
  'Core',
  'CocoaPods-App',
  'Xcodeproj',
  'Nanaimo'
]

task :run do
  REPOS.each do |repo|
    Bot.new("CocoaPods/#{repo}").run!
  end
end
