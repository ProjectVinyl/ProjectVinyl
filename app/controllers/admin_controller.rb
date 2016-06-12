class AdminController < ApplicationController
  def view
    if !user_signed_in? || !current_user.is_admin
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
  end
  
  def video
    if !user_signed_in? || !current_user.is_admin
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @modificationsAllowed = true
    @video = Video.find(params[:id])
    @artist = @video.artist
    @queue = @artist.videos.where.not(id: @video.id).limit(5).order("RAND()")
  end
  
  def album
    if !user_signed_in? || !current_user.is_admin
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @modificationsAllowed = true
    @album = Album.find(params[:id])
    @items = @album.album_items
  end
  
  def artist
    if !user_signed_in? || !current_user.is_admin
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @artist = Artist.find(params[:id])
  end
  
  def transferItem
    if user_signed_in? && current_user.is_admin
      if artist = Artist.where(id: params[:artist]).first
        if params[:type] == 'video'
          item = Video.where(id: params[:id]).first
        elsif params[:type] == 'album'
          item = Album.where(id: params[:id]).first
        end
        if item
          item.transferTo(artist)
          render status: 200
          return
        end
      end
    end
    render status: 401, nothing: true
  end
  
  def deleteVideo
    if user_signed_in? && current_user.is_admin
      if video = Video.where(id: params[:id]).first
        video.removeSelf
        render 'view', locals: {notice: '1 Item(s) deleted successfully'}
      else
        render 'view', locals: {error: 'Item could not be found'}
      end
      return
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
  end
  
  def deleteAlbum
    if user_signed_in? && current_user.is_admin
      if album = Album.where(id: params[:id]).first
        album.destroy
        render 'view', locals: {notice: '1 Item(s) deleted successfully'}
      else
        render 'view', locals: {error: 'Item could not be found'}
      end
      return
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
  end
  
  def deleteArtist
    if user_signed_in? && current_user.is_admin
      if artist = Artist.where(id: params[:id]).first
        albums = artist.albums.count
        videos = artist.videos.count
        artist.removeSelf
        render 'view', locals: {notice: (albums + videos + 1).to_s + ' Item(s) deleted successfully'}
      else
        render 'view', locals: {error: 'Item could not be found'}
      end
      return
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
  end
  
  def toggleVisibility
    if user_signed_in? && current_user.is_admin
      video = Video.find(params[:id])
      if video.hidden
        video.hidden = false
        video.save
      else
        video.hidden = true
        video.save
      end
      render json: { :hidden => video.hidden }
      return
    end
    render status: 401, nothing: true
  end
end
