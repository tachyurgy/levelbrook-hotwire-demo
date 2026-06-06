# ⌘K command palette. Results are rendered server-side into a Turbo Frame and
# keyboard-navigated client-side. No client search index.
class CommandController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @commands = build_commands.select { |c| match?(c, @query) }.first(8)
    render partial: "command/results", locals: { commands: @commands, query: @query }
  end

  private

  def match?(command, query)
    return true if query.blank?
    "#{command[:title]} #{command[:subtitle]}".downcase.include?(query.downcase)
  end

  def build_commands
    nav = [
      { title: "Go to Boards",        subtitle: "Kanban", kind: "Nav", url: projects_path },
      { title: "Go to Search",        subtitle: "Find issues", kind: "Nav", url: search_path },
      { title: "Go to Activity",      subtitle: "Feed", kind: "Nav", url: activities_path },
      { title: "Go to Sign-up form",  subtitle: "Live validation", kind: "Nav", url: new_signup_path }
    ]

    projects = Project.all.map do |p|
      { title: p.name, subtitle: "#{p.key} board", kind: "Project", url: project_path(p) }
    end

    issues = Issue.includes(column: :project).order(updated_at: :desc).limit(20).map do |i|
      { title: "#{i.key} #{i.title}", subtitle: i.column.name, kind: "Issue", url: issue_path(i) }
    end

    nav + projects + issues
  end
end
