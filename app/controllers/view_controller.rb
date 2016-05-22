class ViewController < ApplicationController
  def view
    @video = Video.find(params[:id].split(/-/)[0])
    @artist = @video.artist
    @queue = @artist.videos.where.not(id: @video.id).limit(5).order("RAND()")
    @modificationsAllowed = session[:current_user_id] == @artist.id
  end
  
  def upvote
    @video = Video.find(params[:id])
    @video.upvotes = computeCount(params[:incr].to_i, @video.upvotes)
    @video.save
    render :json => { :count => @video.upvotes }
  end
  
  def downvote
    @video = Video.find(params[:id])
    @video.downvotes = computeCount(params[:incr].to_i, @video.downvotes)
    @video.save
    render :json => { :count => @video.downvotes }
  end

  private
  def computeCount(incr, count)
    if count.nil?
      count = 0
    end
    if incr == 0
      return count
    end
    if incr < 0
      if count > 0
        return count - 1
      end
      return count
    end
    return count + 1
  end
end
