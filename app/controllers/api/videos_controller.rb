require 'projectvinyl/elasticsearch/elastic_selector'

module Api
  class VideosController < ApplicationController
    include PathHelper
    
    before_action :pre_filter
    
    def pre_filter
      if !params[:key] || !(@token = ApiToken.validate_token(params[:key]))
        return render json: {
          success: false,
          error: {
            status: 401,
            message: "Unauthorized"
          }
        }, status: :unauthorized
      end
      
      if !@token.hit
        render json: {
          success: false,
          error: {
            status: 429,
            message: "Too Many Requests"
          }
        }, status: 429
      end
      
      @include = (params[:include] || '').split(',').map {|a| a.strip.to_sym}
    end
    
    def index
      @page = params[:page].to_i
      @limit = (params[:limit] || 10).to_i
      
      @limit = @limit > 100 ? 100 : @limit < 1 ? 1 : @limit
      
      if params[:q]
        @videos = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, params[:q]).videos
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
        json[:included][:user] = User.where('id IN ?', @videos.records.pluck(:user_id)).map {|u| user_response}
      end
      
      render json: json
    end
    
    def show
      video = Video.includes(:duplicate).where(id: params[:id]).first
      
      if video && video.duplicate
        video = video.duplicate
      end
      
      if !video || video.hidden
        return render json: {
          success: false,
          error: {
            status: :not_found,
            message: "Not Found"
          }
        }, status: :not_found
      end
      
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
    
    private
    def video_response(video)
      json = {
        data: {
          id: video.id,
          type: :video,
          attributes: {
            title: video.title,
            cover: {
              full: absolute_url(video.thumb),
              thumbnail: absolute_url(video.tiny_thumb(current_user))
            },
            description: video.description,
            source: video.source,
            duration: video.get_duration,
            tags: Tag.split_tag_string(video.tag_string),
            data_modified: video.updated_at,
            date_published: video.created_at
          },
          meta: {
            url: absolute_url(video.link),
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
      }
      
      if @include.include?(:file)
        json[:data][:attributes][:file] = {
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
