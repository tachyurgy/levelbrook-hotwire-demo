class SignupsController < ApplicationController
  def new
    @signup = Signup.new(seats: 5)
  end

  # Per-field live validation: blur a field -> stream-replace just that field's
  # frame with the server-rendered errors. No duplicated client-side rules.
  def validate
    @signup = Signup.new(signup_params)
    @signup.valid? # populate errors
    field = params[:field]
    render turbo_stream: turbo_stream.replace(
      "signup_field_#{field}", partial: "signups/field",
      locals: { signup: @signup, field: field }
    )
  end

  def create
    @signup = Signup.new(signup_params)
    if @signup.valid?
      render turbo_stream: turbo_stream.replace("signup_form", partial: "signups/success", locals: { signup: @signup })
    else
      render turbo_stream: turbo_stream.replace("signup_form", partial: "signups/form", locals: { signup: @signup }),
             status: :unprocessable_entity
    end
  end

  private

  def signup_params
    params.require(:signup).permit(:workspace_name, :subdomain, :email, :seats)
  end
end
