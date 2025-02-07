require 'spec_helper'
require 'rack/test'
require_relative '../../app'

describe Application do

  before(:each) do 
    reset_all_tables
  end

  include Rack::Test::Methods

  let(:app) { Application.new }

  context 'GET /' do
    it 'Lists all peeps in reverse chronological order' do
      response = get('/')

      expect(response.status).to eq(200)
      expect(response.body).to include('This is better than twitter')
      expect(response.body).to include('My very first peep!')
      expect(response.body).to include('<a href="/signup">')
    end
  end

  context 'GET /peeps/new' do
    it 'Displays form to post a new peep when logged in' do
      new_user = User.new
      new_user.email = 'kboo@makersacademy.com'
      new_user.name = 'King Boo'
      new_user.username = 'kboo'
      new_user.password = 'boo123'

      users = UserRepository.new
      users.create(new_user)
      
      post('/login', submitted_email: 'kboo@makersacademy.com', submitted_password: 'boo123')

      response = get('/peeps/new')

      expect(response.status).to eq(200)
      expect(response.body).to include('<form method="POST" action="/peeps">')
      expect(response.body).to include('<input type="text" name="content" ')
    end

    it 'Redirects to home when trying to peep when not logged in' do
      response = get('/peeps/new')

      expect(response.status).to eq(302)
    end
  end

  context 'POST /peeps' do
    it 'Posts a new peep' do
      new_user = User.new
      new_user.email = 'kboo@makersacademy.com'
      new_user.name = 'King Boo'
      new_user.username = 'kboo'
      new_user.password = 'boo123'

      users = UserRepository.new
      users.create(new_user)
      
      post('/login', submitted_email: 'kboo@makersacademy.com', submitted_password: 'boo123')

      response = post('/peeps', content: 'Testing new peep')

      expect(response.status).to eq(200)
      expect(response.body).to include('Peep successfully posted!')
      expect(response.body).to include('<a href="/">')

      get = get('/')
      expect(get.body).to include('Testing new peep')
    end
  end

  context 'GET /signup' do
    it 'Displays sign up form' do
      response = get('/signup')

      expect(response.status).to eq(200)
      expect(response.body).to include('<form method="POST" action="/signup">')
      expect(response.body).to include('<input type="email" name="email" ')
      expect(response.body).to include('<input type="password" name="password" ')
      expect(response.body).to include('<input type="text" name="name" ')
      expect(response.body).to include('<input type="text" name="username" ')
    end
  end

  context 'POST /signup' do
    it 'Successfully creates a new unique account and persists session in homepage' do
      response = post('/signup', name: 'Toad', username: 'mushroomtoad', email: 'toad@makersacademy.com', password: 'mushroom123')

      expect(response.status).to eq(200)
      expect(response.body).to include('Chitter account successfully created!')
      expect(response.body).to include('<a href="/">')

      home = get('/')
      expect(home.status).to eq(200)
      expect(home.body).to include('<button type="button">Log out</button>')
    end

    it 'Fails if email or username already exists' do
      response = post('/signup', name: 'Diddy Kong', username: 'dkong', email: 'dkong@makersacademy.com', password: 'PROBLEM')

      expect(response.status).to eq(400)
      expect(response.body).to include('Error: email or username already exists. Please go back and try again')
    end
  end

  context 'GET /peeps/:id' do
    it 'Opens a specific peep' do
      response = get('/peeps/1')

      expect(response.status).to eq(200)
      expect(response.body).to include('My very first peep!')
    end
  end

  context 'GET /login' do
    it 'Displays login form' do
      response = get('/login')
      
      expect(response.status).to eq(200)
      expect(response.body).to include('<form method="POST" action="/login">')
      expect(response.body).to include('<input type="email" name="submitted_email" ')
      expect(response.body).to include('<input type="password" name="submitted_password" ')
    end
  end

  context 'POST /login' do
    it 'Successfully authenticates user if email and password match' do
      new_user = User.new
      new_user.email = 'kboo@makersacademy.com'
      new_user.name = 'King Boo'
      new_user.username = 'kboo'
      new_user.password = 'boo123'

      users = UserRepository.new
      users.create(new_user)
      
      response = post('/login', submitted_email: 'kboo@makersacademy.com', submitted_password: 'boo123')

      expect(response.status).to eq(200)
      expect(response.body).to include('Login successful!')
    end

    it 'Fails if email or password do not match' do
      new_user = User.new
      new_user.email = 'kboo@makersacademy.com'
      new_user.name = 'King Boo'
      new_user.username = 'kboo'
      new_user.password = 'boo123'

      users = UserRepository.new
      users.create(new_user)
      
      response = post('/login', submitted_email: 'kboo@makersacademy.com', submitted_password: 'boo')

      expect(response.status).to eq(400)
      expect(response.body).to include('Email and password do not match. Please go back and try again')
    end
  end

  context 'GET /account_page' do
    it 'Account page is accessible when user is logged in' do
      new_user = User.new
      new_user.email = 'kboo@makersacademy.com'
      new_user.name = 'King Boo'
      new_user.username = 'kboo'
      new_user.password = 'boo123'

      users = UserRepository.new
      users.create(new_user)
      
      post('/login', submitted_email: 'kboo@makersacademy.com', submitted_password: 'boo123')

      response = get('/account_page')
      
      expect(response.status).to eq(200)
      expect(response.body).to include('King Boo')
    end

    it 'Account page is not accessible when user is not authenticated' do
      response = get('/account_page')
      
      expect(response.status).to eq(302)
    end
  end

  context 'GET /logout' do
    it 'Logs user out of their session' do
      new_user = User.new
      new_user.email = 'kboo@makersacademy.com'
      new_user.name = 'King Boo'
      new_user.username = 'kboo'
      new_user.password = 'boo123'

      users = UserRepository.new
      users.create(new_user)
      
      post('/login', submitted_email: 'kboo@makersacademy.com', submitted_password: 'boo123')

      logout = get('/logout')
      
      expect(logout.status).to eq(302)

      unauthenticated = get('/')
      expect(unauthenticated.status).to eq(200)
      expect(unauthenticated.body).to include('Sign up to Chitter')
    end
  end

end
