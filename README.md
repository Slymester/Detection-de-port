Runport is a port Scanner in Bash Script

This is a custom port scanning script written in Bash, designed for quick network reconnaissance and to provide information on open ports for security purposes. The script is lightweight, flexible, and does not require Nmap or other external scanning tools, relying instead on native Bash commands. 

FEATURES

- **Target IP Prompt**: Requests the target IP address to scan.
- **Scan Speed Selection**: Choose between fast, medium, and slow scan speeds, influencing timeout delay.
- **Scan Type**: Options to scan standard ports, all ports, or a specific port range.
- **Light Verbose Mode**: Displays scan progress as a percentage without overloading the screen.
- **Pause and Resume**: Press `Ctrl+Z` to pause and use `fg` to resume the scan.
- **Stop Scan**: Press `Ctrl+C` to stop the scan.
- **Output File Option**: Option to save scan results in a file.
- **Service Detection**: Identifies standard ports and includes custom services for recognized ports.

USAGE

-Prerequisites

Ensure you have Bash installed (default on most Linux systems). You should also have network permissions to connect to the target IP.

-Running the Script

Clone the repository or download the script file. Make the script executable and run it with the following syntax:

```bash
./scan_script.sh [options]

Options

    -h, --help: Display the help information.
    -v, --verbose: Enables full verbose mode (displays each port tested).
    -p, --port-range <ports>: Specify a custom port range to scan (e.g., 1-1000).

Interactive Prompts

The script will prompt you for additional information as it runs:

    Target IP Address: Enter the IP address you wish to scan.
    Scan Speed: Choose from fast, medium, or slow. Defaults to medium if no selection is made.
    Verbose Mode: Select whether to enable detailed verbose output.
    Save to File: Choose if you’d like to save results to a file and provide a filename.
    Scan Type: Select from:
        Standard ports
        All ports (1-65535)
        Custom range (e.g., 1-1000)

Example Commands

    Display help information:

./scan_script.sh -h

Run a verbose scan on ports 1-100 with results saved to a file:

./scan_script.sh -v -p 1-100

Run a standard port scan with medium speed:

    ./scan_script.sh

Output

The scan results will include a summary of closed and open ports. If specified, results are saved in a timestamped file with details of detected services.

Output Example:

Scanning IP: 192.168.1.1
Progress: 25%
Port 22 open (SSH)
Port 80 open (HTTP)
Port 443 open (HTTPS)
...
Scan completed.
Ports scanned: 1000
Closed ports: 998
Open ports: 2 (22, 80)

Pause, Resume, and Stop

    Pause: Ctrl+Z to pause the scan, fg to resume.
    Stop: Ctrl+C to terminate the scan.

Contributing

Feel free to submit issues, fork the repository, and send pull requests. Contributions are always welcome.
