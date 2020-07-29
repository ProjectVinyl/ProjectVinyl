require 'projectvinyl/elasticsearch/index'
require 'projectvinyl/elasticsearch/elastic_selector'

module Api
  class VideosController < BaseApiController
    def index
      @page = params[:page].to_i
      @limit = (params[:limit] || 10).to_i

      @limit = @limit > 100 ? 100 : @limit < 1 ? 1 : @limit

      if params[:q]
        @videos = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, params[:q], ProjectVinyl::ElasticSearch::Index::VIDEO_INDEX_PARAMS)
        @videos.query(@page, @limit).exec
      else
        @videos = Pagination.paginate(Video.all.order(:id), @page, @limit, false)
      end

      json = {
        success: true,
        page: @videos.page,
        pages: @videos.pages,
        total: @videos.count,
        data: @videos.records.map {|v| video_response v}
      }

      if @include.include?(:user)
        json[:included] = {}
        json[:included][:user] = User.where('id IN ?', @videos.records.pluck(:user_id)).map {|u| user_response(u)}
      end

      render json: json
    end

    def show
      video = Video.includes(:duplicate).where(id: params[:id]).first
      video = video.duplicate if video && video.duplicate

      return fail :not_found, status: :not_found, message: "Not Found" if !video || video.hidden

      json = {
        success: true,
        data: video_response(video)
      }

      if @include.include?(:uploader)
        user = video.user
        if user
          json[:included] = {}
          json[:included][:user] = [user_response(user)]
        end
      end

      render json: json
    end

    def video_response(video)
      VideosController.video_response(video, root_url, current_user, @include)
    end

    def self.video_response(video, root, current_user, include = {})
      json = {
        id: video.id,
        type: :video,
        attributes: {
          title: video.title,
          cover: {
            full: PathHelper.absolute_url(video.thumb, root),
            thumbnail: PathHelper.absolute_url(video.tiny_thumb(current_user), root)
          },
          description: video.description,
          source: video.source,
          duration: video.duration,
          tags: Tag.split_tag_string(video.tag_string),
          data_modified: video.updated_at,
          date_published: video.created_at
        },
        meta: {
          url: PathHelper.absolute_url(video.link, root),
        },
        relationships: {
          user: {
            data: {
              type: :user,
              id: video.user_id
            }
          }
        }
      }

      if include.include?(:file)
        json[:attributes][:file] = {
          filename: video.title,
          mime: video.mime,
          ext: video.file,
          url: video_download_url(video),
          size: File.size(video.video_path).to_f / 2**20
        }
      end

      json
    end

    def user_response(user)
      {
        id: user.id,
        type: :user,
        attributes: {
          username: user.username,
          avatar: absolute_url(user.avatar)
        },
        meta: {
          url: absolute_url(user.link)
        }
      }
    end
  end
end
