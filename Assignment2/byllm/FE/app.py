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

# --- SESSION STATE ---
def initialize_session_state():
    if "session_id" not in st.session_state:
        st.session_state.session_id = ""
    if "chat_history" not in st.session_state:
        st.session_state.chat_history = []
    if "_reload_tasks_once" not in st.session_state:
        st.session_state._reload_tasks_once = True

initialize_session_state()

# --- SIDEBAR ---
with st.sidebar:
    st.title("🧭 Session Controls")
    
    if st.button("🆕 Start New Chat"):
        st.session_state.session_id = ""
        st.session_state.chat_history = []
        st.success("New chat session started!")
    
    st.markdown("---")
    st.markdown("### 📋 Current Tasks")
    if st.button("🔄 Refresh Tasks"):
        st.session_state._reload_tasks_once = True
        st.rerun()

# --- MAIN INTERFACE ---
st.title("📬 AI Task & Email Manager")
tab1, tab2 = st.tabs(["💬 Chat", "📅 Scheduled Tasks"])

# ========================
#       CHAT INTERFACE
# ========================
with tab1:
    # Display chat messages
    chat_container = st.container()
    with chat_container:
        for msg in st.session_state.chat_history:
            with st.chat_message(msg["role"]):
                st.markdown(msg["content"])
    
    # Auto-scroll to bottom
    if st.session_state.chat_history:
        components_html("""
        <script>
            window.parent.document.querySelector('.chat-scroll').scrollTop = 
            window.parent.document.querySelector('.chat-scroll').scrollHeight;
        </script>
        """, height=0)

    # Chat input
    user_input = st.chat_input("Ask me to create a task, send an email, or just chat...")
    
    if user_input:
        # Add user message to chat history
        st.session_state.chat_history.append({"role": "user", "content": user_input})
        
        payload = {
            "utterance": user_input,
            "session_id": st.session_state.session_id
        }
        
        with st.spinner("🤔 Thinking..."):
            try:
                response = requests.post(TASK_MANAGER_ENDPOINT, json=payload, timeout=30)
                
                if response.status_code == 200:
                    data = response.json()
                    reports = data.get("reports", [])
                    
                    if reports:
                        report = reports[0]
                        ai_response = report.get("response", "I apologize, but I couldn't process your request.")
                        session_id = report.get("session_id", "")
                        
                        if session_id:
                            st.session_state.session_id = session_id
                        
                        st.session_state.chat_history.append({
                            "role": "assistant", 
                            "content": ai_response
                        })
                        st.session_state._reload_tasks_once = True
                    else:
                        st.error("⚠️ No response data received from the assistant.")
                        
                else:
                    st.error(f"❌ Backend error {response.status_code}: {response.text}")
                    
            except requests.exceptions.ConnectionError:
                st.error("🔌 Cannot connect to backend. Please ensure the Jaseci server is running on port 8000.")
            except requests.exceptions.Timeout:
                st.error("⏰ Request timed out. Please try again.")
            except Exception as e:
                st.error(f"❌ Unexpected error: {str(e)}")
        
        st.rerun()

# ========================
#    SCHEDULED TASKS
# ========================
with tab2:
    st.header("📋 All Scheduled Tasks")
    
    if st.button("🔄 Refresh Tasks", key="refresh_tasks"):
        st.session_state._reload_tasks_once = True
    
    if st.session_state._reload_tasks_once:
        with st.spinner("Fetching tasks..."):
            try:
                response = requests.post(GET_ALL_TASKS_ENDPOINT, timeout=10)
                
                if response.status_code == 200:
                    data = response.json()
                    reports = data.get("reports", [])
                    
                    if reports and isinstance(reports, list) and len(reports) > 0:
                        tasks_data = reports[0] if isinstance(reports[0], list) else []
                        
                        if tasks_data:
                            # Create DataFrame
                            df = pd.DataFrame(tasks_data)
                            
                            # Display tasks
                            st.dataframe(
                                df, 
                                use_container_width=True, 
                                hide_index=True,
                                column_config={
                                    "task": "Task Description",
                                    "date": "Date",
                                    "time": "Time", 
                                    "status": "Status",
                                    "created_at": "Created At"
                                }
                            )
                            
                            # Summary
                            st.metric("Total Tasks", len(df))
                        else:
                            st.info("🎉 No scheduled tasks found. Start by saying 'Schedule a meeting tomorrow at 2 PM'")
                    else:
                        st.info("📝 No task data available.")
                        
                else:
                    st.error(f"Failed to fetch tasks: {response.status_code}")
                    
            except requests.exceptions.ConnectionError:
                st.error("Cannot connect to backend to fetch tasks.")
            except Exception as e:
                st.error(f"Error fetching tasks: {str(e)}")
        
        st.session_state._reload_tasks_once = False