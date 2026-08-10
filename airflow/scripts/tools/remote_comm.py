#Function to run a command on a remote host via SSH
#Called from checkmon.py
#Takes an address and port, the check is performed using nc

import paramiko

def run_on_rem(ip, port):
    hostname = "203.0.113.33"
    username = "nasadulin"
    key_path = "../pkey"  # Path to the private key
    command = f"nc -vzn -w 1 {ip} {port}"
    port = 2222

    try:
        # Create the SSH client
        client = paramiko.SSHClient()

        # Automatically add new hosts to known_hosts
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        # Load the private key
        private_key = paramiko.Ed25519Key.from_private_key_file(key_path)

        # Connect to the remote machine using the key and a non-standard port
        client.connect(hostname, port=port, username=username, pkey=private_key)

        # Execute the command on the remote machine
        stdin, stdout, stderr = client.exec_command(command)

        # Get the command execution result
        output = stdout.read().decode('utf-8')
        errors = stderr.read().decode('utf-8')
        res = errors.split()

        # Print the result and errors (if any)
#        print("Output:")
#        print(res)
#        if errors:
#            print("Errors:")
#            print(res[4])

        # Close the connection
        client.close()

        if res[4] == 'open':
            return True
        else: return False

    except Exception as e:
        print(f"An error occurred: {e}")

#run_on_rem('203.0.113.32','9182')
