class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to user_path(user), notice: 'ログインしました。'
    else
      flash.now[:alert] = 'メールアドレスまたはパスワードが無効です。'
      render :new
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'ログアウトしました。'
  end
end
