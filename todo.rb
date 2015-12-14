require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require 'pry'
require 'sinatra/content_for'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def completed?(list)
    return false if list[:todos].size == 0
    list[:todos].each do |todo|
      return false if !todo[:completed] 
    end
    true
  end

  def num_completed_todos(list)
   list[:todos].select { |todo| !todo[:completed] }.size
  end

  def list_class(list)
    "complete" if completed?(list)
  end

  def sort_lists(lists, &block)
    incomplete_lists = {}
    complete_lists = {}
    lists.each_with_index do |list, index| 
      if completed?(list)
        complete_lists[list] = index
      else
        incomplete_lists[list] = index
      end
    end
    incomplete_lists.each(&block) 
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    incomplete_todos = {}
    complete_todos = {}
    todos.each_with_index do |todo, index|
      if todo[:completed]
        complete_todos[todo] = index
      else
        incomplete_todos[todo] = index
      end
    end
    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end

end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end
#view all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

#renders new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

#returns the error message or nil if valid
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    "List name must be between 1 and 50 characters."
  end
end

def error_for_todo(name)
  if !(1..100).cover?(name.size)
    "Todo must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "Todo must be unique."
  end
end

# creates new list
post "/lists" do

  list_name = params[:list_name].strip  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created!"
    
    redirect "/lists"
  end  
end

get "/lists/:number" do 
  @list_number = params[:number].to_i
  if @list_number > session[:lists].size
    redirect "/lists"
  end
  @list = session[:lists][@list_number]
  @todos = @list[:todos]
  erb :show_list, layout: :layout
end

get "/lists/:number/edit" do
  @list_name = session[:lists][params[:number].to_i][:name]
  
  erb :edit_list, layout: :layout
end

# Edit the name of an existing List.
post "/lists/:number" do
  @list_name = params[:list_name].strip
  error = error_for_list_name(@list_name)
  list = session[:lists][params[:number].to_i]
  if error
    session[:error] = error
    erb :edit_list
  else
    list[:name] = params[:list_name]
    session[:success] = "The list name has been updated!"
    redirect "/lists/#{params[:number]}"
  end
end

# delete list
post "/lists/:number/delete" do
  session[:lists].delete_at(params[:number].to_i)
  session[:success] = "Todo list was deleted."
  redirect "/lists"
end

# Create a new todo
post "/lists/:list_number/create_todo" do
  @list = session[:lists][params[:list_number].to_i]
  @list_number = params[:list_number]
  text = params[:todo].strip
  error = error_for_todo(text) 
  if error
    session[:error] = error
    erb :show_list
  else
    @list[:todos] << {name: text, completed: false}
    session[:success] = "Your Todo item was added!"
    redirect "/lists/#{@list_number}"
  end
end

# Delete todo
post "/lists/:list_number/delete/:todo_number" do
  @list = session[:lists][params[:list_number].to_i]
  @list[:todos].delete_at(params[:todo_number].to_i)
  session[:success] = "Todo deleted!"
  redirect "/lists/#{params[:list_number]}"
end

post "/lists/:list_number/todos/:todo_number" do
  list_number = params[:list_number].to_i
  @list = session[:lists][list_number]
  todo_number = params[:todo_number].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_number][:completed] = is_completed
  session[:success] = "The Todo has been updated."
  redirect "/lists/#{list_number}"
end

post "/lists/:list_number/complete_all" do
   list_number = params[:list_number].to_i
    @list = session[:lists][list_number]
    @todos = @list[:todos]
    @todos.each do |todo|
      todo[:completed] = true
    end
    redirect "/lists/#{list_number}"
end