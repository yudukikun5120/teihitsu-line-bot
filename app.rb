# frozen_string_literal: true

# app.rb

require 'sinatra'
require 'line/bot'
require 'json'
require 'net/http'
require 'pg'
require 'sinatra/reloader'
require 'dotenv/load'

def client
  @client ||= Line::Bot::Client.new do |config|
    config.channel_id = ENV['LINE_CHANNEL_ID']
    config.channel_secret = ENV['LINE_CHANNEL_SECRET']
    config.channel_token = ENV['LINE_CHANNEL_TOKEN']
  end
end

def fetch_problem(item_id)
  uri = URI.parse "https://teihitsu.deta.dev/items/jyuku_ate/#{item_id}"
  response = Net::HTTP.get_response uri

  JSON.parse(response.body) if response.code == '200'
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

        if rows.count.zero?
          conn.exec('INSERT INTO user_current_status (user_id, state, item_id) VALUES ($1, 0, 0);', [user_id])
        else
          user_status = rows[0]
        end

        case user_status['state'].to_i
        when 0
          MAX_ITEM_NUMBER = 2184
          item_id = rand(1..MAX_ITEM_NUMBER)
        when 1
          item_id = user_status['item_id']
        end

        item = fetch_problem(item_id)

        case user_status['state'].to_i
        when 0
          client.reply_message(
            event['replyToken'],
            {
              type: 'flex',
              altText: "「#{item['problem']}」の読みを記せ｡",
              contents: {
                "type": 'bubble',
                "body": {
                  "type": 'box',
                  "layout": 'vertical',
                  "spacing": 'md',
                  "contents": [
                    {
                      "type": 'box',
                      "layout": 'vertical',
                      "contents": [
                        {
                          "type": 'text',
                          "text": "Q#{item_id}",
                          "align": 'center',
                          "size": 'xxl',
                          "margin": 'none'
                        },
                        {
                          "type": 'text',
                          "text": '次の熟字訓・当て字の読みを記せ｡',
                          "align": 'center',
                          "margin": 'lg'
                        },
                        {
                          "type": 'text',
                          "text": item['problem'],
                          "wrap": true,
                          "weight": 'bold',
                          "margin": 'lg',
                          "align": 'center',
                          "size": '3xl'
                        }
                      ]
                    }
                  ]
                }
              }
            }
          )

          conn.exec('UPDATE user_current_status SET state = 1, item_id = $1 WHERE user_id = $2;', [item_id, user_id])
        when 1
          message_bg_color, message_text_color = if event.message['text'] == item['correct_answer']
                                                   ['#F1421B', '#FFFFFF']
                                                 else
                                                   ['#FFFFFF', '#444444']
                                                 end

          client.reply_message(
            event['replyToken'],
            {
              type: 'flex',
              altText: "答えは「#{item['correct_answer']}」です。",
              contents: {
                "type": 'bubble',
                "body": {
                  "type": 'box',
                  "layout": 'vertical',
                  "spacing": 'md',
                  "contents": [
                    {
                      "type": 'box',
                      "layout": 'vertical',
                      "contents": [
                        {
                          "type": 'text',
                          "text": "Q#{item_id}",
                          "align": 'center',
                          "size": 'lg',
                          "margin": 'none',
                          "color": message_text_color
                        },
                        {
                          "type": 'text',
                          "text": item['problem'],
                          "wrap": true,
                          "weight": 'bold',
                          "margin": 'md',
                          "align": 'center',
                          "size": '3xl',
                          "color": message_text_color
                        },
                        {
                          "type": 'text',
                          "text": item['correct_answer'],
                          "align": 'center',
                          "margin": 'none',
                          "color": message_text_color
                        },
                        {
                          "type": 'separator',
                          "margin": 'xl'
                        },
                        {
                          "type": 'text',
                          "text": item['note'],
                          "color": message_text_color,
                          "margin": 'lg',
                          "wrap": true
                        }
                      ]
                    }
                  ],
                  "backgroundColor": message_bg_color
                }
              }
            }
          )

          conn.exec('UPDATE user_current_status SET state = 0 WHERE user_id = $1;', [user_id])
        end
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
