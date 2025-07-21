class RepositoriesController < ApplicationController
  before_action :require_login
  
  def index
    @repositories = current_user.repositories
  end

  def new
    @repository = current_user.repositories.new
  end

  def create
    @repository = current_user.repositories.new(repository_params)
    if @repository.save
      redirect_to @repository, notice: 'リポジトリが登録されました。'
    else
      render :new
    end
  end

  def show
    @repository = current_user.repositories.find(params[:id])
    @documents = @repository.documents
  end
  
  private
  
  def repository_params
    params.require(:repository).permit(:name, :url)
  end
end
