import os
import ast
import re


def extract_python_structure(file_path: str) -> dict:
    """
    Parse a Python file and extract functions, classes, and docstrings.
    Returns a structured dictionary describing file contents.
    """
    try:
        with open(file_path, "r", encoding="utf-8") as src:
            code = src.read()

        tree = ast.parse(code)
        functions = []
        classes = []

        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                doc = ast.get_docstring(node) or ""
                functions.append({
                    "name": node.name,
                    "args": [arg.arg for arg in node.args.args],
                    "doc": doc.strip()
                })
            elif isinstance(node, ast.ClassDef):
                classes.append({
                    "name": node.name,
                    "methods": [n.name for n in node.body if isinstance(n, ast.FunctionDef)],
                    "doc": ast.get_docstring(node) or ""
                })

        return {
            "type": "python",
            "functions": functions,
            "classes": classes
        }

    except SyntaxError as e:
        return {"type": "python", "error": f"Syntax error: {e}"}
    except Exception as e:
        return {"type": "python", "error": str(e)}




def extract_jac_entities(file_path: str) -> dict:
    """
    Uses simple regex scanning to find walker, node, and edge definitions in Jac files.
    Returns structured content suitable for documentation generation.
    """
    try:
        with open(file_path, "r", encoding="utf-8") as src:
            code = src.read()

        walkers = re.findall(r"\bwalker\s+(\w+)", code)
        nodes = re.findall(r"\bnode\s+(\w+)", code)
        edges = re.findall(r"\bedge\s+(\w+)", code)

        return {
            "type": "jac",
            "walkers": list(set(walkers)),
            "nodes": list(set(nodes)),
            "edges": list(set(edges))
        }

    except Exception as e:
        return {"type": "jac", "error": str(e)}


def identify_file_type(file_path: str) -> str:
    """
    Returns 'python', 'jac', or 'unknown' based on file extension.
    """
    if file_path.endswith(".py"):
        return "python"
    elif file_path.endswith(".jac"):
        return "jac"
    else:
        return "unknown"


def parse_file(file_path: str) -> dict:
    """
    Dispatches parsing to the correct function based on file type.
    """
    file_type = identify_file_type(file_path)
    if file_type == "python":
        return extract_python_structure(file_path)
    elif file_type == "jac":
        return extract_jac_entities(file_path)
    else:
        return {"type": "unknown", "file": os.path.basename(file_path)}