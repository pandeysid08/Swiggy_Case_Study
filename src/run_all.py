import subprocess, sys
from pathlib import Path
here = Path(__file__).parent
for s in ["generate_data.py", "run_analysis.py"]:
    print(f"\n=== {s} ===", flush=True)
    subprocess.run([sys.executable, str(here / s)], check=True)
