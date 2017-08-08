module Forum
  class SearchController < ApplicationController
    def index
      @page = params[:page].to_i
      @title_query = params[:title_query]
      @poster_query = params[:poster_query]
      @text_query = params[:text_query]
      @ascending = params[:order] == '1'
      @category = (params[:category] || 0).to_i
      @results = []
      
      @q = Comment.searchable.where('`comment_threads`.owner_type = "Board"').order(:updated_at, :created_at)
      
      if @title_query
        @q = @q.where('`comment_threads`.title LIKE ?', '%' + @title_query + '%')
      end
      
      if @poster_query
        @q = @q.joins(:direct_user).where('`users`.username LIKE ?', '%' + @poster_query + '%')
      end
      
      if @text_query
        @q = @q.where('bbc_content LIKE ?', "%#{@text_query}%")
      end
      
      if @category > 0
      @q = @q.where('`comment_threads`.owner_id = ?', @category)
      end
      
      if @title_query || @poster_query || @text_query || (@category > 0)
        @results = @q
      end
      
      @results = Pagination.paginate(@results, @page, 20, !@ascending)
    end
    
    def page
      search
      render_pagination 'comment/set', @results, {
        thread: @results.records,
        indirect: true
      }
    end
  end
end
