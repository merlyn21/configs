import requests
import json

from rec2db import insert_fields

# URL for the Reg.ru API request
#api_url = 'https://api.reg.ru/api/regru2/user/get_balance'
api_url = 'https://api.reg.ru/api/regru2/service/get_list'

all_dns = []

# Request parameters
params = {
    'input_format': 'json',       # Request format
    'output_format': 'json',      # Response format
    'username': 'helpdesk@nimbuscorp.example',         # Your Reg.ru login
    'password': '',         # Your Reg.ru password
    'show_expires': '1',          # Include domain registration expiration date in the response
}

# Send the request to the API
response = requests.get(api_url, params=params)

# Check request success and print information
if response.status_code == 200:
    data = response.json()

#    print(data["answer"]["services"])
    for service in data["answer"]["services"]:
#        print(service['dname'])
#        print("----")
        if service['state'] == 'A':
           if service['servtype'] == 'domain' or service['servtype'] == 'srv_ssl_certificate':
#                print(f"{service['dname']} - {service['servtype']} - {service['expiration_date']} - {service['state']}")
                all_dns.append((service['dname'], service['servtype'], service['expiration_date']))

else:
    print(f"HTTP error: {response.status_code}")

for data1 in all_dns:
    print(data1)

print("start record to DB")
insert_fields(all_dns)
