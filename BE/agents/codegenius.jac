include "repomapper.jac";
include "codeanalyzer.jac";
include "docgenie.jac";
include "supervisor.jac";  

walker CodeGenius {
    param target_url: str;

    can execute(target_url: str) -> str {
        try {
            local_dir, project_name = py_call("utils.clone_repo", [target_url]);
            file_overview = spawn RepoMapper -> build_tree(local_dir);
            doc_summary = spawn RepoMapper -> summarize_readme(local_dir);
            analysis_data = spawn CodeAnalyzer -> analyze(local_dir, file_overview);
            report_path = spawn DocGenie -> generate(project_name, doc_summary, file_overview, analysis_data);
            py_call("shutil.rmtree", [local_dir]);
            report f'{{"status": "success", "report": "{report_path}"}}';
        } except err {
            report f'{{"status": "error", "message": "{str(err)}"}}';
        }
    }
}

with entry boot {
    report "🚀 Code Genius Engine Active and Ready!";
}
