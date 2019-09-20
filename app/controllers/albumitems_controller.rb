class AlbumitemsController < Albums::BaseAlbumsController
  def create
    check_then_with(Album) do |album|
      if !(video = Video.where(id: params[:videoId]).first)
        return head :not_found
      end
      
      album.add_item(video)
    end
  end
  
  def update
    check_then_with(AlbumItem) do |item|
      item.move(params[:index].to_i)
    end
  end
  
  def destroy
    check_then_with(AlbumItem) do |item|
      item.destroy
    end
  end
  
  def toggle
    if !(video = Video.where(id: params[:video_id]).first)
      return head :not_found
    end
    
    if !(album = Album.where(id: params[:item]).first)
      return head :not_found
    end
    
    render json: {
      added: album.toggle(video)
    }
  end
end
