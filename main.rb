require 'sinatra'
require 'digest/md5'
require 'active_record'
require 'json'
require 'cgi/escape'

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

# 名前の最大長
username_max = 40
# パスワードの最大長
passward_max = 40
# titleの最大長
title_max = 60
# 記事の最大長
article_max = 1000

# パスワードを確認する関数
# 入力とDBが一致 -> true
# 不一致 -> false
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

# 入力文字列が1文字以上,最大長以下であることを確認する関数
# 1 <= inputstr < maxlen : true
# else : false
def checkstr(inputstr,maxlen)
    if inputstr.size==0 then
      return false
    elsif inputstr.size>maxlen then
      return false
    else
      return true
    end
  end

# loginにリダイレクト 
get '/' do
  redirect '/login'
end

# ログインフォームを表示
get '/login' do
  erb :loginscr
end

# ログイン管理
# 成功 : contentspageにリダイレクト
# 失敗 : failureにリダイレクト
post '/auth' do
  checkflg=true
  username =CGI.escapeHTML(params[:uname])
  pass = CGI.escapeHTML(params[:pass])
  if !checkstr(username,username_max) then
    checkflg=false
  elsif !checkstr(pass,passward_max) then
    checkflg=false
  end
  
  if checkflg==false then
    redirect '/failure3Resister'
  else 
  if(checkpass(username,pass))
    session[:login_flag] = true
    session[:username] = username
    redirect '/contentspage'
  else
    session[:login_flag] = false
    redirect '/failure'
  end
end
end

# ログイン失敗の表示
get '/failure' do
  erb :failure
end

# アカウント作成フォームを表示
get '/createaccount' do
  erb :makeAccount
end

# アカウント作成管理
# 成功 : successResister
# 失敗1(usernameが既に存在) : failure1Registerにリダイレクト
# 失敗2(pass1,pass2が不一致) : failure2Registerにリダイレクト
# 失敗3(入力エラー) : failure3Registerにリダイレクト
post '/newaccount' do
  checkflg=true
  username = CGI.escapeHTML(params[:uname])
  pass1 = CGI.escapeHTML(params[:pass1])
  pass2 = CGI.escapeHTML(params[:pass2])
  if !checkstr(username,username_max) then
    checkflg=false
  elsif !checkstr(pass1,passward_max) then
    checkflg=false
  elsif !checkstr(pass2,passward_max) then
    checkflg=false
  end
  
  if checkflg==false then
    redirect '/failure3Resister'
  else 

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

# アカウント作成成功の表示
get '/successResister' do
  erb :successResister
end

# usernameが既に存在しているエラーを表示
get '/failure1Resister' do
  erb :failure1Resister
end

# pass1,pass2が不一致のエラーを表示
get '/failure2Resister' do
  erb :failure2Resister
end

# 入力エラーの表示
get '/failure3Resister' do
  erb :failure3Resister
end

# パスワードの再発行フォームを表示
get '/forgetpass' do
  erb :forgetpass
end

# パスワードを再発行する処理
# 成功 : successRenewpassにリダイレクト
# 失敗(usernameが存在しない) : unknownUserにリダイレクト
# 失敗(pass1,pass2が不一致) : failure2Resisterにリダイレクト
post '/newpass' do
  checkflg=true
  username = CGI.escapeHTML(params[:uname])
  pass1 = CGI.escapeHTML(params[:pass1])
  pass2 = CGI.escapeHTML(params[:pass2])
  if !checkstr(username,username_max) then
    checkflg=false
  elsif !checkstr(pass1,passward_max) then
    checkflg=false
  elsif !checkstr(pass2,passward_max) then
    checkflg=false
  end
  
  if checkflg==false then
    redirect '/failure3Resister'
  else 
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
end

# パスワードの再発行成功を表示
get '/successRenewpass' do
  erb :successRenewpass
end 

# usernameが見つからないことを表示
get '/unknownUser' do
  erb :unknownUser
end 

# ログイン必須
# コンテンツページを表示
# 未ログイン時 : badrequestにリダイレクト
get '/contentspage' do
  if (session[:login_flag]==true)
    @a = session[:username]
    erb :contents
  else
    erb :badrequest
  end
end

# ログイン必須
# いいね数の多い記事を表示
# 未ログイン時 : badrequestにリダイレクト
get '/ranking' do
  @isarticle=0
  if (session[:login_flag]==true)
    @a = session[:username]
    # userの記事の件数を取得
    @c = Content.select('*').count

    if @c>=1 then # 記事があるとき読み込み
      @s = Content.where("open==1 AND good>0").order('good desc')
      @isarticle=1
    end

    erb :ranking
  else
    erb :badrequest
  end
end

# ログイン必須
# いいね数の多い記事を表示
# 未ログイン時 : badrequestにリダイレクト
get '/beginer' do
  if (session[:login_flag]==true)
    @a = session[:username]
    erb :beginer
  else
    erb :badrequest
  end
end

# ログイン必須
# 記事の新規作成フォームを表示
# 未ログイン時 : badrequestにリダイレクト
get '/newarticle' do
  if (session[:login_flag]==true)
    erb :newarticle
  else
    erb :badrequest
  end
end

# ログイン必須
# ログインしているユーザーの記事だけを表示
# 未ログイン時 : badrequestにリダイレクト
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

# ログイン必須
# 記事の新規作成フォームを表示
# 未ログイン時 : badrequestにリダイレクト
get '/newarticle' do
  if (session[:login_flag]==true)
    erb :newarticle
  else
    erb :badrequest
  end
end

# ログイン必須
# 記事の新規作成処理
# 成功 : successarticleにリダイレクト
# 失敗 : !
# 未ログイン時 : badrequestにリダイレクト
post '/autharticle' do
  if (session[:login_flag]==true)
    # サニタイジング処理を行う場所
    checkflg=true
    title = CGI.escapeHTML(params[:title])
    description = CGI.escapeHTML(params[:description])
    code = CGI.escapeHTML(params[:code])
    result = CGI.escapeHTML(params[:result])
    if !checkstr(title,title_max) then
      checkflg=false
    elsif !checkstr(description,article_max) then
      checkflg=false
    elsif !checkstr(code,article_max) then
      checkflg=false
    elsif !checkstr(result,article_max) then
      checkflg=false
    end
    
    if checkflg==false then
      redirect '/failure3Resister'
    else 

    authtime = Time.now.strftime("%Y/%m/%d %T")
    @a = session[:username]
    r = Random.new
    s = Content.new
    s.id = Digest::MD5.hexdigest(r.bytes(40))
    s.username = @a
    s.date = authtime
    s.title = title
    s.description = description
    s.code = code
    s.result = result
    s.good=0

    if params[:publicbutton] then
      s.open=1
    else
      s.open=0
    end
    s.save
    redirect '/successarticle'
  end
  else
    erb :badrequest
  end
end

# ログイン必須
# 記事の新規作成成功を表示
# 未ログイン時 : badrequestにリダイレクト
get '/successarticle' do
  if (session[:login_flag]==true)
    erb :successarticle
  else
    erb :badrequest
  end
end

# ログイン必須
# 記事の削除処理をしてmyarticleにリダイレクト
# 未ログイン時 : badrequestにリダイレクト
delete '/del' do
  if (session[:login_flag]==true)
    s=Content.find(params[:id])
    s.destroy
    redirect '/myarticle'
  else
    erb :badrequest
  end
end

# ログイン必須
# 記事の詳細を表示
# 未ログイン時 : badrequestにリダイレクト
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

# ログイン必須
# いいねが押されたときの処理をしてcontenspageにリダイレクト
# 未ログイン時 : badrequestにリダイレクト
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

# ログイン必須
# 記事の編集画面を表示
# 未ログイン時 : badrequestにリダイレクト
post '/edit' do
  if (session[:login_flag]==true)
    @a = Content.find(params[:id])
    erb :edit
  else
    erb :badrequest
  end
end

# ログイン必須
# 記事の更新処理
# 成功 : successarticleにリダイレクト
# 失敗 : !
# 未ログイン時 : badrequestにリダイレクト
post '/authedit' do
  if (session[:login_flag]==true)
    checkflg=true
    title = CGI.escapeHTML(params[:title])
    description = CGI.escapeHTML(params[:description])
    code = CGI.escapeHTML(params[:code])
    result = CGI.escapeHTML(params[:result])
    if !checkstr(title,title_max) then
      checkflg=false
    elsif !checkstr(description,article_max) then
      checkflg=false
    elsif !checkstr(code,article_max) then
      checkflg=false
    elsif !checkstr(result,article_max) then
      checkflg=false
    end
    
    if checkflg==false then
      redirect '/failure3Resister'
    else 
    a = Content.find(params[:id])
    authtime = Time.now.strftime("%Y/%m/%d %T")
    a.date = authtime
    a.title = title
    a.description = description
    a.code = code
    a.result = result
    if params[:publicbutton] then
      a.open=1
    else
      a.open=0
    end
    a.save
    redirect '/successarticle'
  end
  else
    erb :badrequest
  end
end

# ログアウトの処理
get '/logout' do
  session.clear
  erb :logout
end

# ログイン必須
# contentsページにおける記事の検索処理
# 未ログイン時 : badrequestにリダイレクト
get '/search/:val' do
  if (session[:login_flag]==true)
  key=params[:val]
  s=Content.where("open==1 AND title LIKE ?","%#{key}%")
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
          id: "none",
          title:"none",
          username:"none",
          date:"none",
          good:"none",
      }
      r.push(d)
  end

  r.to_json
else
  erb :badrequest
end
end