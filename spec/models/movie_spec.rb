require 'rails_helper'
require 'spec_helper'

describe Movie do
  describe 'searching TMDB by keyword' do
    it 'calls Faraday gem' do
      expect(Faraday).to receive(:get).and_call_original
      Movie.find_in_tmdb({ title: 'hacker', language: 'en' })
    end

    it 'calls TMDb with valid API key' do
      expect(Faraday).to receive(:get).with(/api.themoviedb.org.*api_key=/, any_args).and_call_original
      Movie.find_in_tmdb({ title: 'hacker', language: 'en' })
    end

    it 'returns unsaved Movie objects with rating R' do
      results = Movie.find_in_tmdb({ title: 'Olympics', release_year: '2000' })
      expect(results).to be_an(Array)
      expect(results.length).to eq(2)
      expect(results.first).to be_a(Movie)
      expect(results.first.persisted?).to be_falsey
      expect(results.first.title).to eq('Sydney 2000 Olympics Opening Ceremony')
      expect(results.first.rating).to eq('R')
      expect(results.first.description).to include('Coverage of the glorious Olympic Opening Ceremony')
      expect(results.first.release_date).to eq(Date.parse('2000-09-15'))
    end

    it 'filters out movies that already exist in the database' do
      Movie.create!(title: 'Sydney 2000 Olympics Opening Ceremony', rating: 'R', release_date: '2000-09-15', description: 'Existing movie')
      results = Movie.find_in_tmdb({ title: 'Olympics', release_year: '2000' })
      expect(results.length).to eq(1)
      expect(results.first.title).to eq('Sydney 2000 Olympics Closing Ceremony')
    end

    it 'handles error responses gracefully by returning empty array' do
      stub_request(:get, /api.themoviedb.org/).to_return(status: 404, body: '{"results":[]}')
      results = Movie.find_in_tmdb({ title: 'Unknown' })
      expect(results).to eq([])
    end
  end
end
