walker DocGenie {
    can generate(repo_name: str, summary: str, structure_str: str, analysis_str: str) -> str {
        structure = eval(structure_str);
        analysis = eval(analysis_str);

        content = [f"# Documentation Report for {repo_name}", "", "## Summary", summary, "", "## Repository Layout"]
        
        for folder in structure:
            current_dir = folder['dir'] or 'Root Directory'
            content.append(f"### {current_dir}")
            for f in folder['files']:
                content.append(f"- {f}")
            content.append("")

        content.append("## Code Analysis Results")
        for file, details in analysis.items():
            content.append(f"### {file}")
            match details['type']:
                case 'python':
                    funcs = ', '.join(details.get('funcs', []))
                    classes = ', '.join(details.get('classes', []))
                    content.append(f"Functions: {funcs if funcs else 'None'}")
                    content.append(f"Classes: {classes if classes else 'None'}")
                case 'jac':
                    walkers = ', '.join(details.get('walkers', []))
                    nodes = ', '.join(details.get('nodes', []))
                    content.append(f"Walkers: {walkers if walkers else 'None'}")
                    content.append(f"Nodes: {nodes if nodes else 'None'}")
            content.append("")

        content.append("## Code Relationships (Preview Diagram)")
        content.append("```mermaid\ngraph TD\n    A[Core Files] --> B[Modules]\n    B --> C[Utilities]\n```")

        output_file = f"outputs/{repo_name}_report.md"
        py_call("utils.save_markdown", [output_file, '\n'.join(content)])
        report output_file;
    }
}
