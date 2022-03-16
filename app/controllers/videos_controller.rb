class VideosController < Videos::BaseVideosController
  include Searchable

  RATING_TAGS = ['rating:everyone', 'rating:teen', 'rating:mature'].freeze
  def self.rating_tags
    RATING_TAGS
  end

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
    @mature = @video.rating_tags.where(suffex: 'mature').any?

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

    read_search_params(params, default_order: 1)

    @tags = @video.tags.ordered
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
    return error('Read Only', 'That feature is currently disabled.') if ApplicationHelper.read_only && !current_user.is_contributor?

    @upload_gateway = upload_gateway
    @user = current_user
    @video = Video.new
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

    @rating = @video.tags.matching(RATING_TAGS)
    @tags = @video.tags
    @upload_gateway = upload_gateway
    @user = @video.user
  end

  def create
    return api_error_response('Access Denied', 'You can\'t do that right now.') if !user_signed_in?
    return api_error_response('Read Only', 'That feature is currently disabled.') if ApplicationHelper.read_only && !current_user.is_contributor?

    file = params[:video][:file]

    return api_error_response('Invalid File', 'File is empty') if !file || file.size == 0
    return api_error_response('Invalid File', "Unsupported format: '#{file.content_type}'") if !file.content_type.include?('video/') && !file.content_type.include?('audio/')

    checksum = Verification::VideoVerification.ensure_uniq(file.read)

    return api_error_response('Duplication Error', 'The uploaded video already exists.') if !checksum[:valid]

    Video.transaction do
      @video = current_user.videos.create(
        title: file.original_filename,
        description: '',
        source: '',
        upvotes: 0,
        downvotes: 0,
        views: 0,
        duplicate_id: 0,
        hidden: true,
        listing: 2,
        processed: false,
        draft: true
      )

      @video.upload_media(file, checksum)
      @video.save

      @comments = @video.create_comment_thread(user: current_user, title: @video.title)
      @comments.save
    end

    @comments.subscribe(current_user) if current_user.subscribe_on_upload?

    EncodeFilesJob.perform_later(@video.id)
    ExtractThumbnailJob.queue_video(@video, nil, 0) if !@video.audio_only

    render json: {
      success: true,
      upload_id: @video.id,
      media_update_url: upload_gateway + video_media_path(@video),
      details_update_url: upload_gateway + video_path(@video),
      params: @video.thumb_picker_header
    }
  end

  def update
    api_error_response('Access Denied', "You can't do that right now.") if !user_signed_in?

    if !(@video = Video.where(id: params[:id]).first)
      return api_error_response('404', 'Record not found')
    end

    return api_error_response('Access Denied', "You can't do that right now.") if !@video.owned_by(current_user)

    video = params[:video]

    if params[:_intent] == 'publish'
      return api_error_response('Error', 'You need at least one tag.') if video[:tag_string].blank?
    end

    source = PathHelper.clean_url(video[:source])

    tags = params[:tags]
      .permit(:contributors, :characters, :spoilers)
      .to_hash
      .map{|key, value| Tag.split_to_names(value)}
      .flatten
    tags += Tag.split_to_names(video[:tag_string])
    tags << 'source needed' if !source
    tags -= RATING_TAGS
    tags << RATING_TAGS[video[:rating].to_i]
    tags = tags.uniq

    begin
      if (changes = @video.set_all_tags(TagRule.test(Tag.create_from_names(tags))))
        TagHistory.record_tag_changes(changes[0], changes[1], @video.id, current_user.id)
      end
    rescue TagRule::RuleNotFulfilledError => e
      return api_error_response('Tagging Requirements Not Met', e.message) if params[:_intent] == 'publish'
    end

    @video.comment_thread.locked = video[:commenting].to_i != 0
    @video.title = StringsHelper.check_and_trunk(video[:title], 'Untitled Video')
    @video.comment_thread.title = @video.title
    @video.safe_title = PathHelper.url_safe(@video.title)
    @video.description = video[:description]
    @video.listing = video[:listing].to_i

    was_draft = @video.draft

    if @video.draft && params[:premier][:premier] == '1'
      begin
        @video.premiered_at = DateTime.parse(params[:premier][:date] + ' ' + params[:premier][:time])
        PremierVideoJob.enqueue_video(@video) if params[:_intent] == 'publish'
      rescue ArgumentError => e
        return api_error_response('Error', 'Premier was not specified in a valid date-time format') if params[:_intent] == 'publish'
      end
    end

    if @video.source != source
      @video.source = source
      TagHistory.record_source_changes(@video, current_user.id)
    end

    @video.publish if params[:_intent] == 'publish' && @video.draft && @video.premiered_at.nil?
    @video.save
    @video.comment_thread.save

    return redirect_to action: :show, id: @video.id if params[:format] != 'json'
    render json: {
      success: true,
      ref: params[:_intent] == 'publish' && was_draft && @video.ref
    }
  end

  def destroy
    if !(video = current_user.videos.where(id: params[:id], draft: true).first)
      return api_error_response('404', 'Record not found')
    end

    #video.destroy
    render json: {
      success: true,
      discard: true
    }
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
