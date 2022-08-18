# frozen_string_literal: true

# app.rb

require 'sinatra'
require 'line/bot'
require 'json'
require 'net/http'
require 'pg'
require 'sinatra/reloader'
require 'dotenv/load'
require_relative 'quiz'

def client
  @client ||= Line::Bot::Client.new do |config|
    config.channel_id = ENV['LINE_CHANNEL_ID']
    config.channel_secret = ENV['LINE_CHANNEL_SECRET']
    config.channel_token = ENV['LINE_CHANNEL_TOKEN']
  end
end

def initialize_user(conn, user_id)
  conn.exec('INSERT INTO user_current_status (user_id, item_id) VALUES ($1, 0);', [user_id])
end

def welcome_messages(event)
  new_quiz = Quiz.new event
  messages = [new_quiz.question_message]

  [new_quiz, messages]
end

def quiz_messages(rows, event)
  user_status = rows[0]
  former_quiz = Quiz.new event, user_status['item_id']
  new_quiz = Quiz.new event
  messages = [former_quiz.answer_message, new_quiz.question_message]

  [new_quiz, messages]
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  error 400 do 'Bad Request' end unless client.validate_signature(body, signature)

  events = client.parse_events_from(body)
  events.each do |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        user_id = event['source']['userId']
        conn = PG.connect(host: ENV['DB_HOST'], dbname: ENV['DB_NAME'], user: ENV['DB_USER'],
                          password: ENV['DB_PASSWORD'])
        rows = conn.exec('SELECT * FROM user_current_status WHERE user_id = $1;', [user_id])

        is_new_user = rows.count.zero?
        initialize_user(conn, user_id) if is_new_user

        new_quiz, messages = is_new_user ? welcome_messages(conn, user_id, event) : quiz_messages(rows, event)

        client.reply_message(event['replyToken'], messages)
        conn.exec('UPDATE user_current_status SET item_id = $1 WHERE user_id = $2;', [new_quiz.id, user_id])

        conn.finish
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open('content')
        tf.write(response.body)
      end
    end
  end

  # Don't forget to return a successful response
  'OK'
end
