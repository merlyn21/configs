import requests
import yaml
import re
from datetime import datetime

from send import send2channel

def format_bytes(size):
    # 2**10 = 1024
    power = 2**10
    n = 0
    power_labels = {0 : '', 1: 'Kb', 2: 'Mb', 3: 'Gb', 4: 'Tb'}
    while size > power:
        size /= power
        n += 1
    return f"{round(size, 1)}{power_labels[n]}"

todayd = datetime.now().strftime('%Y-%m-%d')
#datetime.today().date()
print(todayd)
response = requests.get('http://203.0.113.31:9943/metrics')

pattern = r'(?P<metric_name>[\w_]+){path="(?P<path>[^"]+)"}\s(?P<value>[\d.e+-]+)'

modif_time = []
size_file = []
count_zero = 0
message_send = f"Veeam report for {todayd}:\n"

if response.status_code == 200:
#    print(response.text)
    for line in response.text.splitlines():
        if not line.startswith('#') and line.startswith('file'):
#            print(line)
            match = re.search(pattern, line)
            if match:
                metric_name = match.group('metric_name')
                path = match.group('path')
                if line.startswith('file_stat_modif_time_seconds'):
                    value = datetime.fromtimestamp(float(match.group('value'))).strftime('%Y-%m-%d')
                    if value == todayd:
#                        print(f"Metric Name: {metric_name} Path: {path} Value: {value}")
#                        modif_time[path] = value
                        modif_time.append((path, value))
                if line.startswith('file_stat_size_bytes'):
                    value = float(match.group('value'))
                    size_file.append((path, value))
                    for i in range(len(modif_time)):
                        if modif_time[i][0] == path:
                            if value:
                                res = True
#                                str_m += f" {path} {value}\n"
                            else:
                                res = False
                                count_zero += 1
#                                str_m += f" {path} {value}\n"
                            message_send += f"{modif_time[i][0]} {format_bytes(value)}\n"
                            modif_time[i] = (modif_time[i][0], modif_time[i][1], value, res)
#                            mf[3]
#                    size_file[path] = value

#                print(f"Metric Name: {metric_name} Path: {path} Value: {value}")


count_files = len(modif_time)

#if count_zero == 0:
#    message = f"Veeam: Total archives today {count_files}. No zero-size archives"
#else:
#    message = f"Veeam:"
if count_zero > 0:
    message_send = "\U0000274C Warning! There are zero-size files!\n" + message_send

print(message_send)
send2channel(message_send)
#print(modif_time)
