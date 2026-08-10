import nmap

# Function to scan ports
def scan_ports(ip):
    nm = nmap.PortScanner()
    nm.scan(ip, '20-30')  # Scan ports 1 to 1024, you can change the range as needed
    open_ports = []
    for proto in nm[ip].all_protocols():
        lport = nm[ip][proto].keys()
        for port in lport:
            if nm[ip][proto][port]['state'] == 'open':
                open_ports.append(port)
    return open_ports

# Example usage of the function
ip = '192.168.101.55'  # Replace with the desired IP address
open_ports = scan_ports(ip)
print(f"Open ports for {ip}: {open_ports}")

