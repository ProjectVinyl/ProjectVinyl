class VideosController < Videos::BaseVideosController
  def show
    if !(@video = Video.where(id: params[:id]).with_likes(current_user).first)
      if params[:format] == 'json'
        return head :not_found
      end

      return render_error(
        title: 'Nothing to see here!',
        description: 'This is not the video you are looking for.'
      )
    end

    if @video.duplicate_id > 0
      flash[:alert] = 'The video you are looking for has been marked as a duplicate of the one below.'
      return redirect_to action: :show, id: @video.duplicate_id
    end

    if !@video.unlisted? && !@video.visible_to?(current_user)
      return render_error(
        title: 'Content Removed',
        description: "The video you are trying to access is currently not available. Reason: #{@video.moderation_note}"
      )
    end

    load_album

    @time = (params[:t] || params[:resume]).to_i
    @resume = !params[:resume].nil?

    if params[:format] == 'json'
      if !@album
        if !(params[:list] || params[:q])
          return render json: {
            success: true,
            data: Api::VideosController.video_response(@video, root_url, current_user)
          }
        end

        return head :not_found
      end

      return render json: {
        id: @album.album_items.where(index: @index).first.id,
        prev: @prev_video ? {
          link: @prev_video.link,
          id: @prev_video.id
        } : nil,
        next: @next_video ? {
          link: @next_video.link,
          id: @next_video.id
        } : nil,
        current: @video.widget_parameters(@time, @resume, false, @album)
      }
    end

    @order = '1'

    @page = params[:page] ? params[:page].to_i - 1 : 0

    @tags = @video.tags
    @user = @video.user
    @thread = @video.comment_thread
    @comments = @thread.get_comments(current_user).with_likes(current_user)
    @comments = Pagination.paginate(@comments, @page, 10, true)
    @queue = @user.queue(@video.id, current_user)

    @metadata = {
      og: {
        type: @video.audio_only ? 'music.song' : 'video.other',
        album: @album ? {
          track: @index
        } : {}
      },
      type: @video.audio_only ? :music : :video,
      mime: @video.mime,
      title: @video.title,
      duration: @video.get_duration,
      file: PathHelper.absolute_url(@video.webm_url, root_url),
      description: @video.description,
      url: url_for(action: :show, controller: :videos, id: @video.id, only_path: false) + "-" + (@video.safe_title || "untitled-video"),
      embed_url: url_for(action: :show, controller: 'embed/videos', only_path: false, id: @video.id),
      cover: PathHelper.absolute_url(@video.thumb, root_url),
      tags: @tags,
      oembed: @album ? {
        list: @album.id,
        index: @index
      } : {}
    }

    if !(@modifications_allowed = user_signed_in? && current_user.id == @user.id)
      @video.views += 1
      @video.compute_hotness.save
    end
  end

  def new
    if !user_signed_in?
      return render_access_denied
    end

    if ApplicationHelper.read_only && !current_user.is_contributor?
      return render_error(
        title: "Read Only",
        description: "That feature is currently disabled."
      )
    end

    @upload_path = '//' + Rails.application.config.gateway + videos_path
    @user = current_user
    @video = Video.new
  end

  def create
    if !user_signed_in?
      return error("Access Denied", "You can't do that right now.")
    end

    if ApplicationHelper.read_only && !current_user.is_contributor?
      return error("Read Only", "That feature is currently disabled.")
    end

		user = current_user
    video = params[:video]

    file = video[:file]
    cover = video[:cover]

    if !file || file.size == 0
      return error("Error", "File is empty")
    end

    if !file.content_type.include?('video/') && !file.content_type.include?('audio/')
      return error("Error", "Mismatched content type: '#{file.content_type}'" )
    end

    if file.content_type.include?('audio/')
      if !cover || cover.size == 0 || !cover.content_type.include?('image/')
        return error("Error", "Cover art is required for audio files.")
      end
    end

    premier_time = nil
    
    if params[:premier][:premier] == '1'
      begin
        premier_time = DateTime.parse(params[:premier][:date] + ' ' + params[:premier][:time])
      rescue ArgumentError => e
        return error("Error", "Premier was not specified in a valid date-time format")
      end
    end

    if video[:tag_string].blank?
      return error("Error", "You need at least one tag.")
    end

    data = file.read
    if !(checksum = Verification::VideoVerification.ensure_uniq(data))[:valid]
      return error("Duplication Error", "The uploaded video already exists.")
    end

    ext = File.extname(file.original_filename)
    if ext.blank?
      ext = Mimes.ext(file.content_type)
    end

    title = StringsHelper.check_and_trunk(video[:title], "Untitled Video")

    Video.transaction do
      @video = user.videos.create(
        title: title,
        safe_title: PathHelper.url_safe(title),
        description: video[:description],
        source: PathHelper.clean_url(video[:source]),
        audio_only: file.content_type.include?('audio/'),
        file: ext,
        mime: file.content_type,
        upvotes: 0, downvotes: 0, views: 0, duplicate_id: 0,
        hidden: premier_time != nil,
        premiered_at: premier_time,
        processed: false,
        checksum: checksum[:value]
      )

      @comments = @video.comment_thread = CommentThread.create(user_id: user, title: title)
      @comments.save

      if current_user.subscribe_on_upload?
        @comments.subscribe(current_user)
      end

      if @video.source && !@video.source.blank?
        TagHistory.record_source_changes(@video, current_user.id)
      else
        video[:tag_string] = Tag.append_tag_strings(video[:tag_string], 'source needed')
      end

      Tag.load_tags(video[:tag_string], @video)
    end

    @video.video = data
    @video.set_thumbnail(cover, video[:time])
    @video.save
    
    if @video.premiered_at != nil
      PremierVideoJob.set(wait_until: @video.premiered_at.in_time_zone).perform_later(@video.id)
    end

    if params[:format] == 'json'
      return render json: {
        result: "success",
        ref: @video.link
      }
    end
    redirect_to action: :show, id: @video.id
  end

  def update
    if !user_signed_in?
      return head 401
    end

    if !(video = Video.where(id: params[:id]).first)
      return head :not_found
    end

    if !video.owned_by(current_user)
			return head 401
		end

		if params[:field] == 'description'
			video.description = params[:value]
			render json: { content: BbcodeHelper.emotify(video.description) }
		elsif params[:field] == 'title'
			video.set_title(params[:value])
			render json: { content: video.title }
		end

    video.save

  end

  def edit
    if !user_signed_in?
      return render_access_denied
    end

    if !(@video = Video.where(id: params[:id]).first)
      return render_error(
        title: 'Nothing to see here!',
        description: 'This is not the video you are looking for.'
      )
    end

    if !@video.owned_by(current_user)
      return render_access_denied
    end

    @upload_path = '//' + Rails.application.config.gateway + video_cover_path(@video)
    @user = @video.user
  end

  def index
    by_type do |is_admin, results|
      render_listing_total results.with_likes(current_user).order(:created_at), params[:page].to_i, 50, true, {
        is_admin: is_admin, table: 'videos', label: 'Video',
        template: 'pagination/omni_search'
      }
    end
  end
end
