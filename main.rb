require 'sinatra'
require 'digest/md5'
require 'active_record'
require 'json'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

set :environment,:production
set :sessions,
    expire_after: 7200,
    secret: 'Endkq8ty2ll0hnt48sm1b'

class User < ActiveRecord::Base
end

class Content < ActiveRecord::Base
end

username_max = 40
passward_max = 40

def checkpass(trial_username,trial_passwd)
  # Search recorded info
  begin
    a = User.find(trial_username)
    db_username = a.username
    db_salt = a.salt                                                                                                                                                                                                                                                                                                                                                                                                                                    
    db_hashed = a.hashed
    db_algo = a.algo
  rescue => e
    puts "User #{trial_username} is not found."
    puts e.message
    return false
  end

  # Generate a hashed value
  if db_algo == "1"
    trial_hashed = Digest::MD5.hexdigest(db_salt+trial_passwd)
  else
    puts "Unknown algorithm is used for user #{trial_username}."
    return false
  end

  if db_hashed == trial_hashed
    return true
  else
    return false
  end
end

def checkstr(inputstr,maxlen)
    if inputstr.size==0 then
      return false
    elsif inputstr.size>maxlen then
      return false
    else
      return true
    end
  end

get '/' do
  redirect '/login'
end

get '/login' do
  erb :loginscr
end

post '/auth' do
  username = params[:uname]
  pass = params[:pass]

  if(checkpass(username,pass))
    session[:login_flag] = true
    session[:username] = username
    redirect '/contentspage'
  else
    session[:login_flag] = false
    redirect '/failure'
  end
end

get '/createaccount' do
  erb :makeAccount
end

post '/newaccount' do
  checkflg=true
  if !checkstr(params[:uname],username_max) then
    checkflg=false
  elsif !checkstr(params[:pass1],passward_max) then
    checkflg=false
  elsif !checkstr(params[:pass2],passward_max) then
    checkflg=false
  end
  
  if checkflg==false then
    redirect '/failure3Resister'
  else 
  username = params[:uname]
  pass1 = params[:pass1]
  pass2 = params[:pass2]
  begin
    a = User.find(username)
    redirect '/failure1Resister'
  rescue => e
    if pass1==pass2 then
      r = Random.new
      algorithm = "1"
      salt = Digest::MD5.hexdigest(r.bytes(20))
      hashed = Digest::MD5.hexdigest(salt+pass1)
      s = User.new
      s.id = username
      s.salt = salt
      s.hashed = hashed
      s.algo = algorithm
      s.save
      redirect '/successResister'
    else
      redirect '/failure2Resister'
    end
  end
end
end

get '/successResister' do
  erb :successResister
end

get '/failure1Resister' do
  erb :failure1Resister
end

get '/failure2Resister' do
  erb :failure2Resister
end

get '/failure3Resister' do
  erb :failure3Resister
end

get '/failure' do
  erb :failure
end

get '/forgetpass' do
  erb :forgetpass
end

post '/newpass' do
  username = params[:uname]
  pass1 = params[:pass1]
  pass2 = params[:pass2]
  begin
    a = User.find(username)
    if pass1==pass2 then
      r = Random.new
      algorithm = "1"
      salt = Digest::MD5.hexdigest(r.bytes(20))
      hashed = Digest::MD5.hexdigest(salt+pass1)
      a.salt = salt
      a.hashed = hashed
      a.algo = algorithm
      a.save
      redirect '/successRenewpass'
    else
      redirect '/failure2Resister'
    end
  rescue => e
    redirect '/unknownUser'
  end
end

get '/successRenewpass' do
  erb :successRenewpass
end 

get '/unknownUser' do
  erb :unknownUser
end 

get '/contentspage' do
  if (session[:login_flag]==true)
    @a = session[:username]
    @c = Content.select('*').where('open == 1').count
    if @c>=1 then
      @s =  Content.select('*').where('open == 1')
    end
    erb :contents
  else
    erb :badrequest
  end
end

get '/myarticle' do
  @isarticle=0
  if (session[:login_flag]==true)
    @a = session[:username]
    # userの記事の件数を取得
    @c = Content.select('*').where('username == '+"'"+@a+"'").count

    if @c>=1 then # 記事があるとき読み込み
      @s = Content.select('*').where('username == '+"'"+@a+"'")
      @isarticle=1
    end

    erb :myarticle
  else
    erb :badrequest
  end
end

get '/newarticle' do
  if (session[:login_flag]==true)
    erb :newarticle
  else
    erb :badrequest
  end
end

post '/autharticle' do
  if (session[:login_flag]==true)
    # サニタイジング処理を行う場所
    authtime = Time.now.strftime("%Y/%m/%d %T")
    @a = session[:username]
    r = Random.new
    s = Content.new
    s.id = Digest::MD5.hexdigest(r.bytes(40))
    s.username = @a
    s.date = authtime
    s.title = params[:title]
    s.description = params[:description]
    s.code = params[:code]
    s.result = params[:result]
    s.good=0

    if params[:publicbutton] then
      s.open=1
    else
      s.open=0
    end
    s.save
    redirect '/successarticle'
  else
    erb :badrequest
  end
end

get '/successarticle' do
  if (session[:login_flag]==true)
    erb :successarticle
  else
    erb :badrequest
  end
end

delete '/del' do
  if (session[:login_flag]==true)
    s=Content.find(params[:id])
    s.destroy
    redirect '/myarticle'
  else
    erb :badrequest
  end
end

post '/detail' do
  if (session[:login_flag]==true)
    @cookieu = session[:username]
    @a = Content.find(params[:id])
    if @cookieu.eql?(@a.username) then
      @user_flg=true
    else
      @user_flg=false
    end

    erb :detail
  else
    erb :badrequest
  end
end

post '/good' do
  if (session[:login_flag]==true)
    a = Content.find(params[:id])
    a.good +=1
    a.save
    redirect '/contentspage'
  else
    erb :badrequest
  end
end

post '/edit' do
  if (session[:login_flag]==true)
    @a = Content.find(params[:id])
    erb :edit
  else
    erb :badrequest
  end
end

post '/authedit' do
  if (session[:login_flag]==true)
    a = Content.find(params[:id])
    authtime = Time.now.strftime("%Y/%m/%d %T")
    a.date = authtime
    a.title = params[:title]
    a.description = params[:description]
    a.code = params[:code]
    a.result = params[:result]
    if params[:publicbutton] then
      a.open=1
    else
      a.open=0
    end
    a.save
    redirect '/successarticle'
  else
    erb :badrequest
  end
end

get '/logout' do
  session.clear
  erb :logout
end

get '/search/:val' do
  key=params[:val]
  if key.size==0 then
    s=Content.select('*').where('open == 1')
  else
    s=Content.where("open==1 AND title LIKE ?","%#{key}%")
  end
  puts s
  l=s.length
  r=[]

  r.push(kensu: "#{l}")
  if l != 0 && l <= 100
      s.each do |a|
          d = {
              id: "#{a.id}",
              title: "#{a.title}",
              username: "#{a.username}",
              date: "#{a.date}",
              good: "#{a.good}",
          }
          r.push(d)
      end
  else
      d={
          id: "#{a.id}",
          title:"none",
          username:"none",
          date:"none",
          good:"none",
      }
      r.push(d)
  end

  r.to_json
end