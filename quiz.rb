# frozen_string_literal: true

require 'json'

MAX_ITEM_NUMBER = 2184

# The quiz object for message data.
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
    File.open './messages/question.json' do |f|
      message = JSON.parse f.read

      message['altText'] = "「#{@problem['problem']}」の読みを記せ｡"
      contents = message['contents']['body']['contents'][0]['contents']
      contents[0]['text'] = "Q#{@id}"
      contents[2]['text'] = @problem['problem']

      return message
    end
  end

  def answer_message
    message_bg_color, message_text_color = set_background_color

    File.open './messages/answer.json' do |f|
      message = JSON.parse f.read

      message['altText'] = "答えは「#{@problem['correct_answer']}」です。"
      contents = message['contents']['body']['contents'][0]['contents']
      contents[0]['text'] = "Q#{@id}"
      contents[1]['text'] = @problem['problem']
      contents[2]['text'] = @problem['correct_answer']
      contents[4]['text'] = @problem['note']
      contents[0]['color'] = contents[1]['color'] = contents[2]['color'] = contents[4]['color'] = message_text_color
      message['contents']['body']['backgroundColor'] = message_bg_color

      return message
    end
  end

  def answer_is_correct?
    @event.message['text'] == @problem['correct_answer']
  end

  def set_background_color
    answer_is_correct? ? ['#F1421B', '#FFFFFF'] : ['#FFFFFF', '#444444']
  end
end
