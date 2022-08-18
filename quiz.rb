# frozen_string_literal: true

MAX_ITEM_NUMBER = 2184

class Quiz
  attr_reader :id

  def initialize(event, id = sample_id)
    @problem = fetch_problem(@id = id)
    @event = event
  end

  def sample_id
    (1..MAX_ITEM_NUMBER).to_a.sample
  end

  def fetch_problem(id)
    uri = URI.parse "https://teihitsu.deta.dev/items/jyuku_ate/#{id}"
    response = Net::HTTP.get_response uri

    JSON.parse(response.body) if response.code == '200'
  end

  def question_message
    {
      type: 'flex',
      altText: "「#{@problem['problem']}」の読みを記せ｡",
      contents: {
        type: 'bubble',
        body: {
          type: 'box',
          layout: 'vertical',
          spacing: 'md',
          contents: [
            {
              type: 'box',
              layout: 'vertical',
              contents: [
                {
                  type: 'text',
                  text: "Q#{@id}",
                  align: 'center',
                  size: 'xxl',
                  margin: 'none'
                },
                {
                  type: 'text',
                  text: '次の熟字訓・当て字の読みを記せ｡',
                  align: 'center',
                  margin: 'lg'
                },
                {
                  type: 'text',
                  text: @problem['problem'],
                  wrap: true,
                  weight: 'bold',
                  margin: 'lg',
                  align: 'center',
                  size: '3xl'
                }
              ]
            }
          ]
        }
      }
    }
  end

  def answer_message
    message_bg_color, message_text_color = set_background_color
    {
      type: 'flex',
      altText: "答えは「#{@problem['correct_answer']}」です。",
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
                  "text": "Q#{@id}",
                  "align": 'center',
                  "size": 'lg',
                  "margin": 'none',
                  "color": message_text_color
                },
                {
                  "type": 'text',
                  "text": @problem['problem'],
                  "wrap": true,
                  "weight": 'bold',
                  "margin": 'md',
                  "align": 'center',
                  "size": '3xl',
                  "color": message_text_color
                },
                {
                  "type": 'text',
                  "text": @problem['correct_answer'],
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
                  "text": @problem['note'],
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
  end

  def answer_is_correct?
    @event.message['text'] == @problem['correct_answer']
  end

  def set_background_color
    answer_is_correct? ? ['#F1421B', '#FFFFFF'] : ['#FFFFFF', '#444444']
  end
end
