import from byllm.llm { Model }
import from email.mime.text { MIMEText }
import from dotenv { load_dotenv }
import smtplib;
import os;

with entry {
    load_dotenv();
}

# Using Gemini as specified in your requirements
glob llm = Model(model_name="gemini/gemini-2.5-flash", verbose=false);

node Memory {}

node Session {
    has history: list = [];
    has created_at: str = std.get_current_datetime();

    def add_history(entry: str) {
        self.history = self.history + [entry];
    }
    
    def get_history -> str {
        return "\n".join(self.history[-10:]);  # Last 10 messages
    }
}

node Task {
    has task: str = "";
    has date: str = "";
    has time: str = "";
    has status: str = "pending";
}

node TaskHandling {
    def add_task(task: str, date: str, time: str) -> str {
        task_node = Task(task=task, date=date, time=time, status="pending");
        self ++> task_node;
        return "Task: '" + task + "' on " + date + " at " + time + " added successfully";
    }
    
    def check_scheduled_tasks -> list[Task] {
        return [self --> (`?Task)];
    }
    
    def extract_task_info(utterance: str) -> str by llm(
        method="ReAct",
        tools=([self.add_task, std.get_current_datetime])
    );
    
    def summarize_tasks() -> str by llm(
        method="ReAct",
        tools=([self.check_scheduled_tasks])
    );
    
    def route_and_run(utterance: str, history: str) -> str by llm(
        method="ReAct",
        tools=([self.extract_task_info, self.summarize_tasks])
    );
    
    can execute with task_manager entry {
        session = visitor.session;
        response = self.route_and_run(visitor.utterance, session.get_history());
        session.add_history(
            "user: " + visitor.utterance + "\nai: " + response
        );
        report {
            "session_id": jid(session),
            "created_at": session.created_at,
            "response": response
        };
    }
}

sem TaskHandling.extract_task_info = "Extract task details including description, date, and time from user input. Use add_task function to store the task.";
sem TaskHandling.summarize_tasks = "Provide a summary of all scheduled tasks with their details.";
sem TaskHandling.route_and_run = "Route to appropriate task function based on user request.";

node EmailHandling {
    has sender_email: str = os.getenv("SENDER_EMAIL");
    has sender_password: str = os.getenv("SENDER_PASSWORD");
    has sender_name: str = os.getenv("SENDER_NAME");

    def write_email_content(utterance: str, history: str) -> str by llm();
    
    def send_email(email_content: str, email_subject: str, email_to: str) -> str {
        msg = MIMEText(email_content);
        msg["Subject"] = email_subject;
        msg["From"] = f"{self.sender_name} <{self.sender_email}>";
        msg["To"] = email_to;

        try {
            with smtplib.SMTP("smtp.gmail.com", 587) as server {
                server.starttls();
                server.login(self.sender_email, self.sender_password);
                server.sendmail(self.sender_email, [email_to], msg.as_string());
            }
            return "Email sent successfully to " + email_to;
        } catch {
            return "Failed to send email to " + email_to;
        }
    }
    
    def route_and_run(utterance: str, history: str) -> str by llm(
        method="ReAct",
        tools=([self.write_email_content, self.send_email])
    );
    
    can execute with task_manager entry {
        session = visitor.session;
        response = self.route_and_run(visitor.utterance, session.get_history());
        session.add_history(
            "user: " + visitor.utterance + "\nai: " + response
        );
        report {
            "session_id": jid(session),
            "created_at": session.created_at,
            "response": response
        };
    }
}

sem EmailHandling.route_and_run = "Step 1: Extract email content, subject, and recipient from user's message. Step 2: Generate complete email draft and ask for user confirmation. Step 3: Only send email if user explicitly confirms.";

node GeneralChat {
    def chat(utterance: str, history: str) -> str by llm();
    
    def route_and_run(utterance: str, history: str) -> str by llm(
        method="ReAct",
        tools=([self.chat])
    );
    
    can execute with task_manager entry {
        session = visitor.session;
        response = self.route_and_run(visitor.utterance, session.get_history());
        session.add_history(
            "user: " + visitor.utterance + "\nai: " + response
        );
        report {
            "session_id": jid(session),
            "created_at": session.created_at,
            "response": response
        };
    }
}

enum RoutingNodes {
    TaskHandling,
    EmailHandling, 
    GeneralChat
}

walker init {
    root: here = {};
    std.log("AI Assistant System Initialized");
    
    # Initialize memory if it doesn't exist
    if (!(root --> `?Memory`)) {
        root ++> Memory();
    }
    
    std.log("System ready! Use: jac run main.jac -walk agent -ctx '{\"utterance\": \"your message\"}'");
    
    with exit {
        destroy here;
    }
}

walker task_manager {
    has utterance: str = "";
    has session_id: str = "";
    has session: Session = null;

    obj __specs__ {
        static has auth: bool = false;
    }
    
    def route_to_node(utterance: str, history: str) -> RoutingNodes by llm();
    
    can execute with entry {
        # Find or create memory node
        memory_list = [root --> (`?Memory`)];
        if not memory_list {
            memory_list = [root ++> Memory()];
        }
        memory = memory_list[0];
        
        # Find or create session
        if not self.session_id {
            session_list = memory ++> Session();
            self.session = session_list[0];
            self.session_id = jid(self.session);
        } else {
            self.session = &(self.session_id);
        }
        
        # Route to appropriate node using LLM
        routed_node = self.route_to_node(self.utterance, self.session.get_history());
        
        # Create and visit the appropriate node based on routing decision
        if routed_node.value == "TaskHandling" {
            node_inst = TaskHandling();
        } else if routed_node.value == "EmailHandling" {
            node_inst = EmailHandling();
        } else {
            node_inst = GeneralChat();
        }
        
        visit [-> node_inst];
    }
}

walker get_all_tasks {
    obj __specs__ {
        static has auth: bool = false;
    }
    
    can get_all_tasks with entry {
        task_handlers = [root --> (`?TaskHandling`)];
        if not task_handlers {
            report "No tasks found";
            disengage;
        }
        tasks = [task_handlers[0] --> (`?Task`)];
        report tasks;
    }
}

walker get_all_sessions {
    obj __specs__ {
        static has auth: bool = false;
    }
    
    can get_all_sessions with entry {
        memory_nodes = [root --> (`?Memory`)];
        if not memory_nodes {
            report "No sessions found";
            disengage;
        }
        sessions = [memory_nodes[0] --> (`?Session`)];
        report [{
            "id": jid(session),
            "created_at": session.created_at,
            "message_count": session.history.length
        } for session in sessions];
    }
}