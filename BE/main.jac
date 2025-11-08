include repomapper.jac;
include codeanalyzer.jac;
include docgenie.jac;
include supervisor.jac;

walker codebase_builder {
    param repo_url: str;

    can execute(repo_url: str) -> str {
        try {
            local_repo, repo_title = py_call("utils.clone_repo", [repo_url]);
            structure_overview = spawn RepoMapper -> generate_map(local_repo);
            readme_brief = spawn RepoMapper -> extract_summary(local_repo);
            analysis_summary = spawn CodeAnalyzer -> process_repo(local_repo, structure_overview);
            doc_result = spawn DocGenie -> build_docs(repo_title, readme_brief, structure_overview, analysis_summary);
            py_call("shutil.rmtree", [local_repo]);

            report f'{{"status": "success", "docs_path": "{doc_result}"}}';
        } except err {
            report f'{{"status": "failed", "message": "{str(err)}"}}';
        }
    }
}

with entry startup {
    report "📘 Documentation Engine Initialized.";
}
