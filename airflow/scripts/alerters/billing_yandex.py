import time
import jwt
import json
import requests

from send import send2channel

# Read the private key from the JSON file
with open('../authorized_key.json', 'r') as f: 
  obj = f.read()
  obj = json.loads(obj)
  private_key = obj['private_key']
  key_id = obj['id']
  service_account_id = obj['service_account_id']

now = int(time.time())
payload = {
        'aud': 'https://iam.api.cloud.yandex.net/iam/v1/tokens',
        'iss': service_account_id,
        'iat': now,
        'exp': now + 3600
      }

# Build the JWT.
encoded_token = jwt.encode(
    payload,
    private_key,
    algorithm='PS256',
    headers={'kid': key_id}
  )

#Write the key to a file
#with open('jwt_token.txt', 'w') as j:
#   j.write(encoded_token)

# Print to console
#print(encoded_token)

data = {'jwt': encoded_token}
headers = {'Content-Type': 'application/json'}
response = requests.post('https://iam.api.cloud.yandex.net/iam/v1/tokens', headers=headers, json=data)

#print(response.text)

iam_token = json.loads(response.text)['iamToken']

#print(iam)
#get billing -----------------------

url = "https://billing.api.cloud.yandex.net/billing/v1/billingAccounts"

#iam_token = ''

# Request headers using the IAM token
headers = {
    "Authorization": f"Bearer {iam_token}"
}

# Execute the request
response = requests.get(url, headers=headers)

# Check that the request succeeded
if response.status_code == 200:
    billing_accounts = response.json()
#    print(billing_accounts)
    bill = round(float(json.loads(response.text)['billingAccounts'][0]['balance']), 2)
    print(bill)
    message_send = f"Current Yandex Cloud Nimbuscorp balance: {bill}"
    print(message_send)
    send2channel(message_send)
else:
    message_send = f"\U0000274C Error retrieving billing accounts: {response.status_code} - {response.text}"
    print(message_send)
    send2channel(message_send)


