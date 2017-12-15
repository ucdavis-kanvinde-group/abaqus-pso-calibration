import psutil
KILLPROCS = ("pre.exe","standard.exe")
for proc in psutil.process_iter():
    if proc.name() in KILLPROCS:
        proc.kill()
        proc.wait(timeout=60)