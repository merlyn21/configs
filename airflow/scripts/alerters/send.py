#Send messages to the Telegram channel

import requests
import yaml

with open('../config.yml', 'r') as file:
    config = yaml.safe_load(file)


def send2channel(message):
    bot_token = config['telegram']['bot_token']
    channel_id = config['telegram']['channel_id']
    url = config['telegram']['url']

#    print(url)

    # Request parameters
    params = {
      'chat_id': channel_id,
      'text': message
#      'parse_mode': 'Markdown'
    }

    # Send the message
#    response = requests.get(url, params=params)
    response = requests.post(url, data=params)

    # Check the response
    if response.status_code == 200:
        print('Message sent successfully!')
    else:
        print(f'Failed to send message: {response.status_code} - {response.text}')


#send2channel('Test')
