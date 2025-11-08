walker RepoMapper {
    can build_tree(repo_path: str) -> str {
        files_map = py_call("utils.explore_repo", [repo_path]);
        # Return as JSON-like string
        report str(files_map);
    }

    can summarize_readme(repo_path: str) -> str {
        # Try reading and summarizing README content
        readme_text = py_call("utils.fetch_readme_text", [repo_path]);
        summary_text = py_call("utils.create_readme_summary", [readme_text]);
        report summary_text;
    }
}
