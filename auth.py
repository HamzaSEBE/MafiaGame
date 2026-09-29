import pty
import os
import sys
import re

pid, fd = pty.fork()

if pid == 0:
    # Child process
    os.environ["PATH"] = os.getcwd() + "/gh_2.55.0_linux_amd64/bin:" + os.environ.get("PATH", "")
    os.environ["GH_PROMPT_DISABLED"] = "0" 
    os.execvp("gh", ["gh", "auth", "login", "--hostname", "github.com", "--git-protocol", "https", "--web"])
else:
    # Parent process
    output = ""
    try:
        while True:
            data = os.read(fd, 1024).decode(errors='replace')
            output += data
            # print(data, end='') # For debugging
            
            if "? Authenticate Git with your GitHub credentials?" in output:
                os.write(fd, b"Y\n")
                output = ""
            
            if "First copy your one-time code" in output or "https://github.com/login/device" in output:
                # We reached the device code screen, let's wait a bit to read the code
                import time
                time.sleep(1)
                more_data = os.read(fd, 1024).decode(errors='replace')
                output += more_data
                break
    except OSError:
        pass
    
    # print("\n--- Captured ---")
    # print(output)
    
    # Try to parse the code
    # Usually it looks like: First copy your one-time code: XXXX-XXXX
    match = re.search(r'one-time code: ([A-Z0-9-]+)', output)
    if match:
        print("CODE:", match.group(1))
    else:
        print("Could not find code. Output was:", output)
