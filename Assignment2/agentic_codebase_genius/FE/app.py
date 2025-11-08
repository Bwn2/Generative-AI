import subprocess
import json
import sys
from flask import Flask, request, jsonify

app = Flask(__name__)

def run_mkulima_smart(repo_url: str):
    """
    Calls the Jac walker 'codebase_builder' in main.jac
    Returns a dict with status and report path.
    """
    try:
        result = subprocess.run(
            ["jac", "run", "main.jac", "--repo_url", repo_url],
            capture_output=True,
            text=True,
            check=True
        )
        output = result.stdout.strip()
        try:
            return json.loads(output)
        except json.JSONDecodeError:
            return {"status": "error", "message": "Invalid Jac output", "raw_output": output}

    except subprocess.CalledProcessError as e:
        return {"status": "error", "message": str(e), "stderr": e.stderr}


if __name__ == "__main__":
    if len(sys.argv) > 1:
        repo = sys.argv[1]
        response = run_mkulima_smart(repo)
        print(json.dumps(response, indent=2))
    else:
        print("Usage: python app.py <git_repo_url>")
        print("Example: python app.py https://github.com/user/project.git")



@app.route("/mkulimasmart/generate", methods=["POST"])
def generate_docs():
    data = request.json
    repo_url = data.get("repo_url")
    if not repo_url:
        return jsonify({"status": "error", "message": "Missing repo_url"}), 400

    output = run_mkulima_smart(repo_url)
    return jsonify(output)


if __name__ != "__main__":
    print("MkulimaSmart server ready! 🚀")
