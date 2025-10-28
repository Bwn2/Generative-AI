import streamlit as st
import requests
import pandas as pd
from streamlit.components.v1 import html as components_html

# --- PAGE CONFIG ---
st.set_page_config(
    page_title="AI Task & Email Manager",
    page_icon="📬", 
    layout="wide"
)

st.markdown("""
<style>
    .main > div {
        max-width: 1100px;
        margin: 0 auto;
        padding: 1rem 2rem;
    }
    
    .stTabs {
        position: sticky;
        top: 0;
        background-color: white;
        z-index: 100;
        padding: 0.5rem 0;
        border-bottom: 1px solid #eee;
    }
    
    /* Enhanced chat layout from Lecs */
    .chat-wrapper {
        display: flex;
        flex-direction: column;
        height: calc(100vh - 200px);
        overflow: hidden;
    }
    
    .chat-scroll {
        flex: 1;
        overflow-y: auto;
        padding: 1rem 0;
        margin-bottom: 1rem;
        max-height: calc(100vh - 300px);
        scroll-behavior: smooth;
    }
    
    /* Better scrollbar from Lecs */
    .chat-scroll::-webkit-scrollbar { width: 8px; }
    .chat-scroll::-webkit-scrollbar-track { background: #f1f1f1; border-radius: 4px; }
    .chat-scroll::-webkit-scrollbar-thumb { background: #888; border-radius: 4px; }
    .chat-scroll::-webkit-scrollbar-thumb:hover { background: #555; }
    
    .stChatMessage { margin-bottom: 1rem; }
</style>
""", unsafe_allow_html=True)

# --- CONSTANTS ---
BASE_URL = "http://localhost:8000"
TASK_MANAGER_ENDPOINT = f"{BASE_URL}/walker/task_manager"
GET_ALL_TASKS_ENDPOINT = f"{BASE_URL}/walker/get_all_tasks"

# --- ROBUST SESSION STATE ---
if "session_id" not in st.session_state:
    st.session_state.session_id = ""
if "chat_history" not in st.session_state:
    st.session_state.chat_history = []
if "_reload_tasks_once" not in st.session_state:
    st.session_state._reload_tasks_once = True

# --- SIDEBAR ---
with st.sidebar:
    st.title("🧭 Session Controls")
    if st.button("🆕 Start New Chat"):
        st.session_state.session_id = ""
        st.session_state.chat_history = []
        st.success("New chat session started!")

# --- MAIN INTERFACE ---
st.title("📬 AI Task & Email Manager")
tab1, tab2 = st.tabs(["💬 Chat", "📅 Scheduled Tasks"])

# ========================
#       CHAT INTERFACE
# ========================
with tab1:

    chat_container = st.container()
    with chat_container:
        messages_container = st.container()
        with messages_container:
            st.markdown('<div id="chat-scroll" class="chat-scroll">', unsafe_allow_html=True)
            for msg in st.session_state.chat_history:
                with st.chat_message(msg["role"]):
                    st.markdown(msg["content"])
            st.markdown("</div>", unsafe_allow_html=True)
        
        # Auto-scroll
        if st.session_state.chat_history:
            components_html("""
            <script>
            setTimeout(() => {
                const el = window.parent.document.getElementById('chat-scroll');
                if (el) el.scrollTop = el.scroll.scrollHeight;
            }, 100);
            </script>
            """, height=0)

    # Chat input
    user_input = st.chat_input("Ask me to create a task, send an email, or just chat...")
    
    # Enhanced message handling 
    if user_input:
        st.session_state.chat_history.append({"role": "user", "content": user_input})
        
        payload = {
            "utterance": user_input,
            "session_id": st.session_state.session_id
        }
        
        with st.spinner("🤔 Thinking..."):
            try:
                # Add timeout 
                res = requests.post(TASK_MANAGER_ENDPOINT, json=payload, timeout=30)
                if res.status_code == 200:
                    data = res.json()
                    reports = data.get("reports", [])
                    if reports:
                        report = reports[0]
                        response = report.get("response", "No response text found.")
                        session_id = report.get("session_id", "")
                        if session_id:
                            st.session_state.session_id = session_id
                        st.session_state.chat_history.append({"role": "assistant", "content": response})
                    else:
                        st.error("⚠️ No valid response received from backend.")
                else:
                    st.error(f"❌ Backend returned error {res.status_code}")
            except requests.exceptions.ConnectionError:
                st.error("⚠️ Unable to connect to backend. Make sure it's running on port 8000.")
            except Exception as e:
                st.error(f"Unexpected error: {e}")
        
        st.rerun()

# ========================
#    SCHEDULED TASKS
# ========================
with tab2:
    st.header("📋 All Scheduled Tasks")
    
    col1, _ = st.columns([1, 3])
    with col1:
        refresh = st.button("🔄 Refresh")
    
    should_load = st.session_state.get("_reload_tasks_once", True) or refresh
    if should_load:
        with st.spinner("Fetching tasks..."):
            try:
                res = requests.post(GET_ALL_TASKS_ENDPOINT)
                if res.status_code == 200:
                    data = res.json()
                    reports = data.get("reports", [])
                    tasks = reports[0] if reports and isinstance(reports[0], list) else []
                    if tasks:
                        flat_tasks = []
                        for t in tasks:
                            ctx = t.get("context", {})
                            flat_tasks.append({
                                "Task": ctx.get("task", ""),
                                "Date": ctx.get("date", ""),
                                "Time": ctx.get("time", ""),
                                "Status": ctx.get("status", "")
                            })
                        df = pd.DataFrame(flat_tasks)
                        st.dataframe(df, use_container_width=True, hide_index=True)
                    else:
                        st.info("✅ No scheduled tasks found.")
                else:
                    st.error(f"Backend returned {res.status_code}")
            except Exception as e:
                st.error(f"Error fetching tasks: {e}")
        
        st.session_state._reload_tasks_once = False