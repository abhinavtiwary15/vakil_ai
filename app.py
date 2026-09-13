"""
Streamlit Web Interface for Vakil AI - Indian Legal Q&A Assistant for MSMEs.
"""

import streamlit as st
import os
import json
from src.generator import generate_answer, DISCLAIMER

st.set_page_config(
    page_title="Vakil AI — Legal Assistant for Indian MSMEs",
    page_icon="⚖️",
    layout="wide"
)

# Custom Styling
st.markdown("""
<style>
    .main-header {
        font-size: 2.2rem;
        font-weight: 700;
        color: #1E3A8A;
        margin-bottom: 0.2rem;
    }
    .sub-header {
        font-size: 1.05rem;
        color: #4B5563;
        margin-bottom: 1.5rem;
    }
    .disclaimer-banner {
        background-color: #FEF3C7;
        border-left: 4px solid #F59E0B;
        padding: 0.8rem 1rem;
        font-size: 0.88rem;
        color: #92400E;
        border-radius: 4px;
        margin-bottom: 1.5rem;
    }
    .citation-box {
        background-color: #F3F4F6;
        border: 1px solid #E5E7EB;
        padding: 0.6rem 0.8rem;
        border-radius: 6px;
        font-size: 0.85rem;
        margin-top: 0.5rem;
    }
</style>
""", unsafe_allow_html=True)

# App Header
st.markdown('<div class="main-header">⚖️ Vakil AI — Indian Legal Q&A Assistant</div>', unsafe_allow_html=True)
st.markdown('<div class="sub-header">Authoritative, statute-grounded legal assistant for Indian MSMEs & Business Owners.</div>', unsafe_allow_html=True)

# Mandatory Top Disclaimer
st.markdown(f'<div class="disclaimer-banner">⚠️ <b>Mandatory Notice:</b> {DISCLAIMER}</div>', unsafe_allow_html=True)

# Sidebar with Statutes Info
with st.sidebar:
    st.header("📚 Ingested Statutes")
    st.caption("Verbatim statutory text fetched directly from India Code (indiacode.gov.in)")
    
    manifest_path = "data/statutes/sources.json"
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = json.load(f)
        for act_key, meta in manifest.get("acts", {}).items():
            with st.expander(f"📌 {meta['short_name']} ({meta['section_count']} sections)"):
                st.write(f"**Full Name:** {meta['act_name']}")
                st.write(f"**Act ID:** `{meta['act_id']}`")
                st.write(f"**Sections Indexed:** {', '.join(meta['sections_captured'][:12])}...")
    
    st.divider()
    st.markdown("### 💡 Example Questions")
    example_prompts = [
        "What interest rate can an MSME claim for delayed payments?",
        "What is the notice period for cheque bounce under Section 138?",
        "Can a GST officer scrutinize my return under Section 61?",
        "Can I claim compensation for breach of contract?",
        "How do I claim adverse possession of land? (Out-of-scope test)"
    ]
    for p in example_prompts:
        if st.button(p, key=f"ex_{p[:20]}"):
            st.session_state["user_input"] = p

# Chat history initialization
if "messages" not in st.session_state:
    st.session_state.messages = [
        {
            "role": "assistant",
            "content": "Namaste! I am Vakil AI. I can answer legal questions on **MSME delayed payments (MSMED Act 2006)**, **cheque dishonour (NI Act 1881)**, **GST scrutiny (CGST Act 2017)**, and **commercial contracts (Indian Contract Act 1872)** based directly on official statutory text.\n\nHow may I help your business today?"
        }
    ]

# Display past chat messages
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])
        if "citations" in msg and msg["citations"]:
            with st.expander("🔗 Official Statutory Citations"):
                for cit in msg["citations"]:
                    st.markdown(f"- **{cit}**")
        if "raw_sources" in msg and msg["raw_sources"]:
            with st.expander("📜 View Raw Verbatim Statutory Excerpts"):
                for s in msg["raw_sources"]:
                    st.markdown(f"**{s.get('citation', '')}**")
                    st.caption(f"Source: [{s['metadata'].get('source_url', '')}]({s['metadata'].get('source_url', '')})")
                    st.code(s.get("content", ""), language="markdown")

# Chat input
user_query = st.chat_input("Ask a legal question regarding MSME compliance, payments, or contracts...")
if "user_input" in st.session_state and st.session_state["user_input"]:
    user_query = st.session_state["user_input"]
    del st.session_state["user_input"]

if user_query:
    # Append user question
    st.session_state.messages.append({"role": "user", "content": user_query})
    with st.chat_message("user"):
        st.markdown(user_query)

    # Generate assistant answer
    with st.chat_message("assistant"):
        with st.spinner("Analyzing official Indian statutes..."):
            result = generate_answer(user_query, top_k=4)
            st.markdown(result["answer"])

            if result["citations"]:
                with st.expander("🔗 Official Statutory Citations"):
                    for cit in result["citations"]:
                        st.markdown(f"- **{cit}**")

            if result["retrieved_chunks"]:
                with st.expander("📜 View Raw Verbatim Statutory Excerpts"):
                    for chunk in result["retrieved_chunks"]:
                        st.markdown(f"**{chunk.get('citation', '')}**")
                        st.caption(f"Source: [{chunk['metadata'].get('source_url', '')}]({chunk['metadata'].get('source_url', '')})")
                        st.code(chunk.get("content", ""), language="markdown")

    # Record in history
    st.session_state.messages.append({
        "role": "assistant",
        "content": result["answer"],
        "citations": result.get("citations", []),
        "raw_sources": result.get("retrieved_chunks", [])
    })
