import os, ast, tempfile, shutil, subprocess, re
from pathlib import Path
from openai import OpenAI

def clone_repo(url):
    if not url.endswith(".git"):
        url += ".git"
    temp_dir = tempfile.mkdtemp(prefix="proj_")
    subprocess.run(["git", "clone", url, temp_dir], check=True, capture_output=True)
    repo_name = Path(url).stem
    return temp_dir, repo_name


def explore_repo(repo_path):
    structure = []
    ignore = {".git", "__pycache__", "venv", ".venv", "node_modules"}
    for root, dirs, files in os.walk(repo_path):
        dirs[:] = [d for d in dirs if d not in ignore]
        rel = os.path.relpath(root, repo_path)
        src = [f for f in files if f.endswith((".py", ".jac"))]
        if src:
            structure.append({"dir": rel if rel != "." else "", "files": src})
    return structure


def fetch_readme_text(repo_path):
    for name in ["README.md", "readme.md", "README.txt"]:
        fpath = os.path.join(repo_path, name)
        if os.path.exists(fpath):
            with open(fpath, "r", encoding="utf-8") as f:
                return f.read()
    return "README not found."


def create_readme_summary(readme_text):
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        return "Summary unavailable (missing key)."
    client = OpenAI(api_key=api_key)
    prompt = f"Provide a 4-sentence summary for this README:\n\n{readme_text[:2000]}"
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.choices[0].message.content


def scan_source(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
        if file_path.endswith(".py"):
            tree = ast.parse(content)
            funcs = [n.name for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)]
            classes = [n.name for n in ast.walk(tree) if isinstance(n, ast.ClassDef)]
            return {"type": "python", "funcs": funcs, "classes": classes}
        elif file_path.endswith(".jac"):
            walkers = re.findall(r"walker\s+(\w+)", content)
            nodes = re.findall(r"node\s+(\w+)", content)
            return {"type": "jac", "walkers": walkers, "nodes": nodes}
        return {"type": "unknown", "content": content[:300]}
    except Exception as e:
        return {"type": "error", "details": str(e)}


def save_markdown(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(data)
