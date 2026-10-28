require 'rails_helper'

describe MoviesController, type: :controller do
  describe 'searching TMDb' do
    before :each do
      @fake_results = [double('movie1'), double('movie2')]
    end

    it 'calls the model method that performs TMDb search' do
      expect(Movie).to receive(:find_in_tmdb).with('hardware').
        and_return(@fake_results)
      get :search_tmdb, params: { search_terms: 'hardware' }
    end

    describe 'after valid search' do
      before :each do
        allow(Movie).to receive(:find_in_tmdb).and_return(@fake_results)
        get :search_tmdb, params: { search_terms: 'hardware' }
      end

      it 'selects the Search Results template for rendering' do
        expect(response).to render_template('search_tmdb')
      end

      it 'makes the TMDb search results available to that template' do
        expect(assigns(:movies)).to eq(@fake_results)
      end
    end

    describe 'with search form submission' do
      it 'calls Movie.find_in_tmdb with search parameters when title is provided' do
        expect(Movie).to receive(:find_in_tmdb).with(
          hash_including(title: 'Manhunter', release_year: '1986', language: 'en')
        ).and_return(@fake_results)
        get :search_tmdb, params: { title: 'Manhunter', release_year: '1986', language: 'en' }
        expect(response).to render_template('search_tmdb')
        expect(assigns(:movies)).to eq(@fake_results)
      end

      it 'shows error and does not call find_in_tmdb when title is blank' do
        expect(Movie).not_to receive(:find_in_tmdb)
        get :search_tmdb, params: { title: '', release_year: '1986' }
        expect(flash.now[:danger]).to eq('Please fill in all required fields!')
        expect(response).to render_template('search_tmdb')
      end

      it 'shows warning when no matching movies are returned' do
        allow(Movie).to receive(:find_in_tmdb).and_return([])
        get :search_tmdb, params: { title: 'Unknown Movie' }
        expect(flash.now[:warning]).to eq('No movies found with given parameters!')
        expect(response).to render_template('search_tmdb')
      end
    end
  end

  describe 'adding movie from TMDb' do
    it 'creates a movie in database and redirects to search with success notice' do
      expect {
        post :add_movie, params: {
          title: 'Limitless',
          rating: 'R',
          release_date: '2011-03-08',
          description: 'A paranoia-fueled action thriller.'
        }
      }.to change(Movie, :count).by(1)

      expect(response).to redirect_to(search_tmdb_path)
      expect(flash[:success]).to eq('Limitless was successfully added to RottenPotatoes.')

      movie = Movie.find_by(title: 'Limitless')
      expect(movie).not_to be_nil
      expect(movie.rating).to eq('R')
      expect(movie.description).to eq('A paranoia-fueled action thriller.')
    end
  end
end
