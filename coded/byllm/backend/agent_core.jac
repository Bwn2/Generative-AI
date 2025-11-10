import from dotenv { load_dotenv }
import sys;
import from utils { get_current_datetime }

node Memory {}

node Session {
    has history: list = [];
    has created_at: str = get_current_datetime();

    def add_history(entry: str) {
        self.history = self.history + [entry];
    }
    
    def get_history -> str {
        return "\n".join(self.history[-10:]);  # Last 10 exchanges
    }
}

node Toolbox {
    def route_and_run(utterance: str, history: str) -> str abs;
    
    can execute with agent entry {
        session = visitor.session;
        response = self.route_and_run(visitor.utterance, session.get_history());
        session.add_history(f"user: {visitor.utterance}");
        session.add_history(f"assistant: {response}");
        report {
            "session_id": jid(visitor.session),
            "response": response
        };
    }
}

walker agent {
    has utterance: str = "";
    has session_id: str = "";
    has session: Session = null;

    obj __specs__ {
        static has auth: bool = False;
    }
    
    def get_node_class(class_name: str) {
        main_mod = sys.modules.get("main");
        if main_mod and hasattr(main_mod, class_name) {
            return getattr(main_mod, class_name, None);
        }

        for (mod_name, mod) in sys.modules.items() {
            if mod and hasattr(mod, class_name) {
                return getattr(mod, class_name);
            }
        }
        return null;
    }
    
    def route_to_node(utterance: str, history: str) -> RoutingNodes abs;
    
    can execute with `root entry {
        memory_list = [root --> (`?Memory)];
        if not memory_list {
            memory_list = root ++> Memory();
        }
        memory = memory_list[0];
        
        if not self.session_id {
            session_list = memory ++> Session();
            self.session = session_list[0];
        } else {
            try {
                self.session = &(self.session_id);
            } catch {
                # Session not found, create new one
                session_list = memory ++> Session();
                self.session = session_list[0];
            }
        }
        
        routed_node = self.route_to_node(self.utterance, self.session.get_history());
        node_cls = self.get_node_class(routed_node.value);
        
        if not node_cls {
            # Fallback to GeneralChat
            node_cls = self.get_node_class("GeneralChat");
        }
        
        node_inst = node_cls();
        visit [-->(`?node_cls)] else {
            attached_routed_node = here ++> node_inst;
            visit attached_routed_node;
        }
    }
}

with entry {
    load_dotenv();
}