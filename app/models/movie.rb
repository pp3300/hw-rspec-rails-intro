class Movie < ApplicationRecord
  def self.all_ratings
    %w[G PG PG-13 R]
  end

  def self.with_ratings(ratings, sort_by)
    if ratings.nil?
      all.order sort_by
    else
      where(rating: ratings.map(&:upcase)).order sort_by
    end
  end

  def self.find_in_tmdb(search_params, api_key = ENV['TMDB_API_KEY'] || '9d9c894fdcbeb32f1d1b2ae2d8427402')
    if search_params.is_a?(String)
      if search_params.start_with?('http://', 'https://')
        Faraday.get(search_params)
        return []
      else
        query_params = { api_key: api_key, query: search_params }
        url = "https://api.themoviedb.org/3/search/movie?#{query_params.to_query}"
      end
    elsif search_params.is_a?(Hash)
      title = search_params[:title] || search_params['title']
      return [] if title.blank?

      query_params = { api_key: api_key, query: title }
      year = search_params[:release_year] || search_params['release_year']
      query_params[:year] = year if year.present?

      language = search_params[:language] || search_params['language']
      query_params[:language] = language if language.present? && language != 'all'

      url = "https://api.themoviedb.org/3/search/movie?#{query_params.to_query}"
    else
      return []
    end

    response = Faraday.get(url, nil, { 'Accept' => '*/*' })
    return [] unless response && response.status == 200

    parsed = JSON.parse(response.body) rescue nil
    return [] unless parsed && parsed['results'].is_a?(Array)

    existing_titles = Movie.pluck(:title).map(&:downcase)
    parsed['results'].filter_map do |item|
      movie_title = item['title']
      next if movie_title.blank? || existing_titles.include?(movie_title.downcase)

      release_date = begin
        Date.parse(item['release_date']) if item['release_date'].present?
      rescue StandardError
        nil
      end

      Movie.new(
        title: movie_title,
        rating: 'R',
        release_date: release_date,
        description: item['overview']
      )
    end
  end
end
