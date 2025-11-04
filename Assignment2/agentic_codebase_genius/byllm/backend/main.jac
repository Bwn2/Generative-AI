import from byllm.llm { Model }
import from email.mime.text { MIMEText }
import from email.mime.multipart { MIMEMultipart }
import smtplib;
import os;
include agent_core;
import from utils { get_current_datetime }

glob llm = Model(model_name="gemini/gemini-2.5-flash", verbose=false);

enum RoutingNodes {
    GENERAL_CHAT = "GeneralChat",
    TASK_HANDLING = "TaskHandling", 
    EMAIL_HANDLING = "EmailHandling"
}

node Task {
    has task: str = "";
    has date: str = "";
    has time: str = "";
    has status: str = "pending";
    has created_at: str = get_current_datetime();
}

node TaskHandling(Toolbox) {
    has task_storage: list[Task] = [];
    
    def add_task(task: str, date: str, time: str) -> str {
        new_task = Task(task=task, date=date, time=time);
        self.task_storage = self.task_storage + [new_task];
        return f"Task '{task}' scheduled for {date} at {time}";
    }
    
    def check_scheduled_tasks -> list[Task] {
        return self.task_storage;
    }
    
    def extract_task_info(utterance: str) -> str by llm(
        method="ReAct",
        tools=([self.add_task, get_current_datetime]),
        instructions="Extract task description, date, and time from the user's utterance. Use get_current_datetime if no specific date is mentioned."
    );
    
    def summarize_tasks() -> str by llm(
        method="ReAct", 
        tools=([self.check_scheduled_tasks]),
        instructions="Provide a summary of all scheduled tasks in a friendly manner."
    );
    
    def route_and_run(utterance: str, history: str) -> str by llm(
        method="ReAct",
        tools=([self.extract_task_info, self.summarize_tasks]),
        instructions="Based on user input, either extract task information or summarize existing tasks. For task creation, use extract_task_info. For checking tasks, use summarize_tasks."
    );
}

node EmailHandling(Toolbox) {
    has sender_email: str = os.getenv("SENDER_EMAIL");
    has sender_password: str = os.getenv("SENDER_PASSWORD");
    has sender_name: str = os.getenv("SENDER_NAME");

    def write_email_content(utterance: str, history: str) -> str by llm(
        instructions="Write professional email content based on user's request. Return only the email body content."
    );
    
    def send_email(email_content: str, email_subject: str, email_to: str) -> str {
        try {
            # Create message
            msg = MIMEMultipart();
            msg['From'] = f"{self.sender_name} <{self.sender_email}>";
            msg['To'] = email_to;
            msg['Subject'] = email_subject;
            
            # Add body to email
            msg.attach(MIMEText(email_content, 'plain'));
            
            # Create server connection
            server = smtplib.SMTP('smtp.gmail.com', 587);
            server.starttls();
            server.login(self.sender_email, self.sender_password);
            text = msg.as_string();
            server.sendmail(self.sender_email, email_to, text);
            server.quit();
            
            return f"Email successfully sent to {email_to}";
        } with exception as e{
            return f"Failed to send email: {str(e)}";
        }
    }
    
    def route_and_run(utterance: str, history: str) -> str by llm(
        method="ReAct",
        tools=([self.write_email_content, self.send_email]),
        instructions="Help users write and send emails. First draft the content, then send it. Ask for missing information like recipient email or subject if needed."
    );
}

node GeneralChat(Toolbox) {
    def chat(utterance: str, history: str) -> str by llm(
        instructions="You are a helpful AI assistant. Provide friendly, helpful responses to general questions and conversations."
    );
    
    def route_and_run(utterance: str, history: str) -> str {
        return self.chat(utterance, history);
    }
}

walker task_manager(agent) {
    def route_to_node(utterance: str, history: str) -> RoutingNodes by llm(
        method="classify",
        instructions="""Classify the user's intent into one of these categories:
        - GENERAL_CHAT: General conversation, questions, greetings
        - TASK_HANDLING: Creating tasks, checking tasks, scheduling, reminders  
        - EMAIL_HANDLING: Sending emails, writing emails, email composition
        
        Examples:
        - "Hello how are you?" -> GENERAL_CHAT
        - "Schedule a meeting tomorrow" -> TASK_HANDLING  
        - "Send an email to John" -> EMAIL_HANDLING
        """
    );
}

walker get_all_tasks {
    obj __specs__ {
        static has auth: bool = False;
    }
    can get_all_tasks with `root entry {
        # Find all Task nodes
        task_nodes = [`root --> Task];
        tasks = [];
        for task_node in task_nodes {
            tasks = tasks + [{
                "task": task_node.task,
                "date": task_node.date, 
                "time": task_node.time,
                "status": task_node.status,
                "created_at": task_node.created_at
            }];
        }
        report tasks;
    }
}