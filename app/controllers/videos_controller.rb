class VideosController < Videos::BaseVideosController
  include Searchable

  configure_ordering [ :date, :rating, [:wilson_score, :wilson_lower_bound], :heat, :length, :random, :relevance ], search_action: :search_index_path, only: [ :index ]

  def show
    if !(@video = Video.where(id: params[:id]).with_likes(current_user).first)
      return head :not_found if params[:format] == 'json'
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

    @video.video_visits.create

    load_album

    @path_type = 'videos'
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
    @queue = @user.queue(@video.id, current_user, current_filter)

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
      duration: @video.duration,
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
      @video.save
    end
  end

  def new
    return render_access_denied if !user_signed_in?

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
    return error("Access Denied", "You can't do that right now.") if !user_signed_in?
    return error("Read Only", "That feature is currently disabled.") if ApplicationHelper.read_only && !current_user.is_contributor?

		user = current_user
    video = params[:video]

    file = video[:file]
    cover = video[:cover]

    return error("Error", "File is empty") if !file || file.size == 0

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

    return error("Error", "You need at least one tag.") if video[:tag_string].blank?

    data = file.read
    if !(checksum = Verification::VideoVerification.ensure_uniq(data))[:valid]
      return error("Duplication Error", "The uploaded video already exists.")
    end

    ext = File.extname(file.original_filename)
    ext = Mimes.ext(file.content_type) if ext.blank?

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

      @comments.subscribe(current_user) if current_user.subscribe_on_upload?

      if @video.source && !@video.source.blank?
        TagHistory.record_source_changes(@video, current_user.id)
      else
        video[:tag_string] = (video[:tag_string].split(',') + ['source needed']).uniq.join(',')
      end

      @video.tag_string = video[:tag_string]
    end

    @video.video = data
    @video.save

    ProcessUploadJob.queue_video(@video, cover, video[:time])

    if params[:format] == 'json'
      return render json: {
        result: "success",
        ref: @video.link
      }
    end
    redirect_to action: :show, id: @video.id
  end

  def update
    return head 401 if !user_signed_in?
    return head :not_found if !(video = Video.where(id: params[:id]).first)
    return head 401 if !video.owned_by(current_user)

		if params[:field] == 'description'
			video.description = params[:value]
			render json: { content: BbcodeHelper.emotify(video.description) }
		elsif params[:field] == 'title'
			video.title = params[:value]
			render json: { content: video.title }
		end

    video.save

  end

  def edit
    return render_access_denied if !user_signed_in?

    if !(@video = Video.where(id: params[:id]).first)
      return render_error(
        title: 'Nothing to see here!',
        description: 'This is not the video you are looking for.'
      )
    end
    return render_access_denied if !@video.owned_by(current_user)

    @upload_path = '//' + Rails.application.config.gateway + video_cover_path(@video)
    @user = @video.user
  end

  def index
    render_paginated find_records, {
      is_admin: @is_admin,
      table: 'videos',
      label: 'Video',
      template: 'pagination/omni_search'
    }
  end

  private
  def find_records
    read_search_params params
    return aha!(current_filter.videos.where_not(duplicate_id: 0), :merged) if params[:merged]
    return aha!(current_filter.videos.where(hidden: true), :unlisted) if params[:unlisted]
    return aha!(current_filter.videos.where(hidden: false, listing: 0, duplicate_id: 0), nil) if !params[:unprocessed]

    configure_pars :unprocessed
    ordering = ProjectVinyl::Search::Order.fields('video', session, @orderby)
    Pagination.paginate(Video.where(processed: nil).order(ordering).for_thumbnails(current_user), @page, 20, !@ascending)
  end

  def aha!(records, key)
    configure_pars key
    records.sort(ProjectVinyl::Search.ordering('video', session, @orderby, @ascending))
           .paginate(@page, 20){|recs| recs.for_thumbnails(current_user)}
  end

  def configure_pars(key)
    @is_admin = !key.nil?
    @data = "#{key}=1" if @is_admin
  end
end
