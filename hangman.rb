require 'sinatra'
require 'sinatra/reloader' if development?
enable :sessions

helpers do
  def store_guess(filename, string) # stores the guess in a file
    File.open(filename, "a+") do |file|
      file.puts(string)
    end
  end

  def read_guesses # gets the guesses back out of a file and sets them to an array
    return [] unless File.exist?("guesses.txt")
    return guess_array=File.read("guesses.txt").split("\n")
  end

  def set_play_word # picks a word from the file
    array = []
    File.foreach('word_list') do |x|
      chomped = x.chomp
      array << chomped if (chomped.length == 7)
    end
    the_word = array.sample.downcase
    return the_word
  end

  def set_blanks_array # creates an array of blanks
    blanks_array=[]
    session[:play_word].length.times {blanks_array<<"_"}
    return blanks_array
  end

  def blanks_array
    session[:blanks_array]
  end

  def blanks_string # formats the blanks array as a string
    return blanks_string= session[:blanks_array].join("")
  end

  def blanks_string_spaces
    return blanks_string_spaces= session[:blanks_array].join(" ")
  end# adds spaces to the blanks string so that it looks better

  def guess_array
    session[:guess_array]
  end

  def check_guess
    session[:play_word].each_char.with_index do |letter, num|
      if letter == params["guess"]
        session[:blanks_array][num]=params["guess"]
      end
    end
    if !session[:play_word].include? params["guess"]
      session[:bad_guess]+=1
    end
    session[:blanks_string]= blanks_string
    session[:blanks_string_spaces] = blanks_string_spaces
  end

  def win # if win or lose page gets redirected
    if  session[:bad_guess] < 10 && session[:play_word] == session[:blanks_string]
      File.open('guesses.txt', 'w') {|file| file.truncate(0) }
      redirect "/win"
    elsif session[:bad_guess] == 10
      File.open('guesses.txt', 'w') {|file| file.truncate(0) }
      redirect "/lose"
    end
  end

  def start_game # triggers methods and sets results as values in sessions hash
    File.open('guesses.txt', 'w') {|file| file.truncate(0) }
    session[:play_word] = set_play_word
    session[:blanks_array] = set_blanks_array
    session[:blanks_string] = blanks_string
    session[:blanks_string_spaces] = blanks_string_spaces
    session[:guess_array]= read_guesses
    session[:bad_guess]=0
  end
end

get '/' do # welcome page
  start_game # calls starts game method once per session
  erb :index, layout: :main # shos the main layout which yeilds to index
end

get '/play' do # stat game button takes us here. gets is only to show current state
  @play_word=session[:play_word] # sets session values to instance variables so they can be passed to the erb files
  @guess= params["guess"]
  @guess_array= session[:guess_array]= read_guesses
  @blanks_array= session[:blanks_array]
  @blanks_string= session[:blanks_string]
  @blanks_string_spaces= session[:blanks_string_spaces]
  @bad_guess=session[:bad_guess]
  erb :play, layout: :main
end

post "/" do # clicking guess will post the new guess save it, check it and check for a win
  @guess= params["guess"]
  store_guess("guesses.txt", @guess)
  check_guess
  win
  redirect "/play"
end

get '/win' do
    @play_word=session[:play_word]
  erb :win, layout: :main # shos the winning page
end

get '/lose' do
  @play_word=session[:play_word]
  erb :lose, layout: :main # shows the losing page
end
