"""
Grounded Legal Generator for Vakil AI.
Answers queries strictly grounded on retrieved Indian statutory sections.
Enforces statutory citations, explicit out-of-scope refusal, and mandatory disclaimer.
"""

import os
from typing import Dict, Any, List
from google import genai
from dotenv import load_dotenv

from src.vector_store import retrieve_sections

load_dotenv()

PREFERRED_MODELS = [
    "models/gemini-3.5-flash-lite",
    "gemini-2.5-flash",
    "models/gemini-2.5-flash",
    "gemini-1.5-flash"
]

DISCLAIMER = "This is legal information, not legal advice. Consult a qualified lawyer for your specific situation."
OUT_OF_SCOPE_PHRASE = "I do not have authoritative statutory provisions on this topic in my current legal knowledge base"

SYSTEM_PROMPT = """You are Vakil AI, an authoritative legal information assistant for Indian MSMEs and business owners.
You provide precise, reliable information based STRICTLY on official Indian statutes.

RULES FOR YOUR RESPONSE:
1. Grounding: Rely ONLY on the provided statutory sections in the context. Do not speculate, hallucinate, or assume legal facts not in the context.
2. Citations: Every legal statement or proposition must cite the specific Act name, section number, and title (e.g., "[MSMED Act, 2006, Section 16 - Date from which and rate at which interest is payable]").
3. Out of Scope / Missing Context: If the user's question asks about a legal area or fact NOT covered by the provided sections (e.g. criminal law outside NI Act, personal/family/divorce law, real estate law, international law, adverse possession), you MUST state clearly:
"I do not have authoritative statutory provisions on this topic in my current legal knowledge base. My current knowledge base is restricted to the MSMED Act 2006, CGST Act 2017, Negotiable Instruments Act 1881 (cheque dishonour), and the Indian Contract Act 1872."
4. Mandatory Disclaimer: Always append the exact disclaimer at the end:
"---
*Disclaimer: This is legal information, not legal advice. Consult a qualified lawyer for your specific situation.*"
5. Clarity for Business Owners: Explain legal conditions, timelines (e.g., notice days, payment deadlines, compounding frequency) clearly and concisely.
"""

def get_gemini_client():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("GEMINI_API_KEY is not set.")
    return genai.Client(api_key=api_key)

def generate_answer(query: str, top_k: int = 4) -> Dict[str, Any]:
    retrieved_chunks = retrieve_sections(query, top_k=top_k)
    
    if not retrieved_chunks:
        answer = (
            f"{OUT_OF_SCOPE_PHRASE}. "
            "My current knowledge base is restricted to the MSMED Act 2006, CGST Act 2017, Negotiable Instruments Act 1881 (cheque dishonour), "
            "and the Indian Contract Act 1872.\n\n"
            "---\n"
            f"*Disclaimer: {DISCLAIMER}*"
        )
        return {
            'answer': answer,
            'citations': [],
            'retrieved_chunks': [],
            'is_out_of_scope': True
        }

    context_parts = []
    citations = []
    for idx, chunk in enumerate(retrieved_chunks, 1):
        context_parts.append(f"--- Section Excerpt {idx} ---\n{chunk['content']}\nSource: {chunk['metadata'].get('source_url', '')}")
        citations.append(chunk['citation'])

    full_context = "\n\n".join(context_parts)
    prompt = f"""Context from Official Indian Statutes:
{full_context}

User Question:
{query}

Provide a grounded, professional response adhering strictly to the system rules. If the context does not answer the question or is irrelevant, use the out-of-scope response rule."""

    client = get_gemini_client()
    
    response_text = None
    last_err = None
    for m in PREFERRED_MODELS:
        try:
            resp = client.models.generate_content(
                model=m,
                contents=prompt,
                config={
                    "system_instruction": SYSTEM_PROMPT,
                    "temperature": 0.1
                }
            )
            response_text = resp.text
            break
        except Exception as e:
            last_err = e
            continue

    if not response_text:
        raise RuntimeError(f"All Gemini models failed. Last error: {last_err}")

    # Check if the LLM determined the query to be out of scope
    is_out_of_scope = OUT_OF_SCOPE_PHRASE.lower() in response_text.lower()

    # Ensure disclaimer is included
    if DISCLAIMER not in response_text:
        response_text += f"\n\n---\n*Disclaimer: {DISCLAIMER}*"

    return {
        'answer': response_text,
        'citations': [] if is_out_of_scope else list(dict.fromkeys(citations)),
        'retrieved_chunks': retrieved_chunks,
        'is_out_of_scope': is_out_of_scope
    }
