module Forums
  class SearchController < ApplicationController
    def index
      @path_type = 'forums'
      @title_query = params[:title_query]
      @poster_query = params[:poster_query]
      @text_query = params[:text_query]
      @category = (params[:board] || 0).to_i
      
      @q = Comment.visible.where("comment_threads.owner_type = 'Board'").order(:updated_at, :created_at).with_likes(current_user)
      @q = @q.where('comment_threads.title LIKE ?', "%#{@title_query}%") if @title_query
      @q = @q.joins(:direct_user).where('users.username LIKE ?', "%#{@poster_query}%") if @poster_query
      @q = @q.where('bbc_content LIKE ?', "%#{@text_query}%") if @text_query
      @q = @q.where('comment_threads.owner_id = ?', @category) if @category > 0

      @results = Pagination.paginate(@q, params[:page].to_i, 20, params[:order] != '1')
      @was_search = true
      
      return render_empty_pagination 'pagination/warden_derpy' if params[:format] == 'json' && @results.count == 0
      render_paginated @results, partial: 'comments/comment', as: :json, indirect: true if params[:format] == 'json'
    end
  end
end
