class SearchController < ApplicationController
  def index
    @query      = params[:q].to_s.strip
    @follow_up  = params[:follow_up].to_s.strip
    @last_query = params[:last_query].to_s.strip
    @results    = nil

    if @query.present?
      @results    = SearchService.call(@query)
      @last_query = @query
      session[:search_history] ||= []
      session[:search_history].unshift(@query)
      session[:search_history] = session[:search_history].uniq.first(5)

      if params[:live].present?
        render turbo_stream: turbo_stream.update(
          "search_results",
          partial: "search/results",
          locals: { results: @results, query: @query, last_query: @last_query }
        )
        return
      end

    elsif @follow_up.present? && @last_query.present?
      combined    = "#{@last_query} — #{@follow_up}"
      @results    = SearchService.call(combined)
      @query      = combined
    end

    @search_history = session[:search_history] || []
  end

  def clear_history
    session[:search_history] = []
    redirect_to search_path
  end
end