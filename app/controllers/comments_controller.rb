class CommentsController < ApplicationController
  def create
    @issue = Issue.find(params[:issue_id])
    @comment = @issue.comments.build(comment_params.merge(member: current_member))

    if @comment.save
      # The model's after_create_commit append-broadcasts to all viewers.
      # We just reset the composer for the submitter.
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(
          "new_comment_#{@issue.id}", partial: "comments/form", locals: { issue: @issue }
        ) }
        format.html { redirect_to issue_path(@issue) }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end
end
