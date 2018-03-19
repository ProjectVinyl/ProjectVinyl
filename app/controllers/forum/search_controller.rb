module Forum
  class SearchController < ApplicationController
    def index
      @title_query = params[:title_query]
      @poster_query = params[:poster_query]
      @text_query = params[:text_query]
      @category = (params[:category] || 0).to_i
      
      @q = []
      
      if @title_query || @poster_query || @text_query || (@category > 0)
        @q = Comment.visible.where('`comment_threads`.owner_type = "Board"').order(:updated_at, :created_at).with_likes(current_user)
        
        if @title_query
          @q = @q.where('`comment_threads`.title LIKE ?', "%#{@title_query}%")
        end
        
        if @poster_query
          @q = @q.joins(:direct_user).where('`users`.username LIKE ?', "%#{@poster_query}%")
        end
        
        if @text_query
          @q = @q.where('bbc_content LIKE ?', "%#{@text_query}%")
        end
        
        if @category > 0
          @q = @q.where('`comment_threads`.owner_id = ?', @category)
        end
      end
      
      @results = Pagination.paginate(@q, params[:page].to_i, 20, params[:order] != '1')
      
      if params[:format] == 'json'
        render_pagination_json 'comment/comment', @results, {
          indirect: true
        }
      end
    end
  end
end
