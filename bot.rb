require 'colored'
require 'octokit'

class Bot
  def initialize(slug)
    @slug = slug
  end

  def client
    @client ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def run!
    puts(('-' * 80).red)
    puts("Fetching issues for: #{@slug.green}")
    puts(('-' * 80).red)

    client.auto_paginate = true
    issues = client.issues(@slug, per_page: 100, state: 'open')
    issues.each do |issue|
      if issue.pull_request.nil?
        process_open_issue(issue)
      end
    end

    puts(('-' * 80).red)
    puts("Completed analysis for: #{@slug.green}")
    puts(('-' * 80).red)
  end

  private

  def process_open_issue(issue)
    process_inactive(issue) if inactive?(issue)
  end

  def inactive?(issue)
    diff_in_months = (Time.now - issue.updated_at) / 60.0 / 60.0 / 24.0 / 30.0
    diff_in_months > 1
  end

  def process_inactive(issue)
    issue_comments = client.issue_comments(@slug, issue.number)
    unless issue_comments.first
      puts "🙈  https://github.com/#{@slug}/issues/#{issue.number}"
      return
    end

    first_commenter_is_last_commenter = issue_comments.first.user.login == issue_comments.last.user.login
    poster_is_last_commenter = issue.user.login == issue_comments.last.user.login

    is_awaiting_input = !!issue.labels.find { |a| a.name == 's1:awaiting input' }
    is_awaiting_validation = !!issue.labels.find { |a| a.name == 's4:awaiting validation' }
    awaiting_user_action = is_awaiting_input || is_awaiting_validation
    has_status_label = !!issue.labels.find do |a| 
      a.name.start_with?('s') ||
        a.name.start_with?('d') ||
        a.name.start_with?('r') ||
        a.name.start_with?('t')
    end

    if awaiting_user_action && poster_is_last_commenter
      print_issue("👀", issue, issue_comments)
      return
    elsif awaiting_user_action && first_commenter_is_last_commenter
      print_issue("🚫", issue, issue_comments)
      return
    elsif awaiting_user_action
      print_issue("⚠️", issue, issue_comments)
      return
    end

    if !has_status_label
      print_issue("❓", issue, issue_comments)
      return
    end
  end

  def print_issue(emoji, issue, issue_comments)
    pretty_labels = issue.labels.map { |i| i.name }.join(', ')
    url = "https://github.com/#{@slug}/issues/#{issue.number}"
    author = issue.user.login
    last_commentor = issue_comments.last.user.login
    puts "#{emoji} | #{url} | #{pretty_labels} | #{author} | #{last_commentor}"
  end
end
