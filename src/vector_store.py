"""
ChromaDB Vector Store for Vakil AI.
Stores section-aware chunks with metadata (Act name, section number, title, source URL).
Provides top_k semantic retrieval + exact section number boosting with source citations.
Includes a calibrated distance-based relevance threshold for semantic search results.
"""

import os
import re
import chromadb
from typing import List, Dict, Any
from src.chunker import process_all_statutes

DB_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'chroma_db')
COLLECTION_NAME = 'indian_statutes'

# Calibrated distance threshold for all-MiniLM-L6-v2 (L2 distance):
# In-scope queries typically fall in range 0.52 - 0.98.
# Truly unrelated / out-of-scope queries (traffic violations, divorce, patents, adverse possession) fall above 1.10.
# Setting threshold to 1.10 ensures semantic search filters out weakly-relevant / out-of-scope chunks.
DEFAULT_DISTANCE_THRESHOLD = 1.10

def get_vector_store():
    os.makedirs(DB_DIR, exist_ok=True)
    client = chromadb.PersistentClient(path=DB_DIR)
    collection = client.get_or_create_collection(
        name=COLLECTION_NAME,
        metadata={"description": "Official Indian Central Acts for MSMEs"}
    )
    return client, collection

def ingest_statutes(force_reload: bool = False):
    client, collection = get_vector_store()
    current_count = collection.count()

    if current_count > 0 and not force_reload:
        print(f"[*] ChromaDB collection already has {current_count} chunks. Skipping re-ingest (use force_reload=True to overwrite).")
        return collection

    if force_reload and current_count > 0:
        print("[*] Clearing existing collection for fresh ingestion...")
        client.delete_collection(COLLECTION_NAME)
        collection = client.get_or_create_collection(
            name=COLLECTION_NAME,
            metadata={"description": "Official Indian Central Acts for MSMEs"}
        )

    print("[*] Loading statute chunks...")
    chunks = process_all_statutes()
    if not chunks:
        print("[!] No chunks found to ingest.")
        return collection

    ids = [c['id'] for c in chunks]
    documents = [c['text'] for c in chunks]
    metadatas = [c['metadata'] for c in chunks]

    batch_size = 50
    for i in range(0, len(chunks), batch_size):
        b_ids = ids[i:i + batch_size]
        b_docs = documents[i:i + batch_size]
        b_metas = metadatas[i:i + batch_size]
        collection.add(ids=b_ids, documents=b_docs, metadatas=b_metas)
        print(f"  [+] Ingested chunks {i+1} to {min(i+batch_size, len(chunks))}")

    print(f"[SUCCESS] Total chunks indexed in ChromaDB: {collection.count()}")
    return collection

def retrieve_sections(query: str, top_k: int = 4, distance_threshold: float = DEFAULT_DISTANCE_THRESHOLD) -> List[Dict[str, Any]]:
    """
    Retrieve relevant statutory sections for a query.
    
    1. Exact section-number boost: if the query explicitly mentions a section (e.g. 'section 138'),
       matching chunks are retrieved with distance=0.1 and ALWAYS pass through.
    2. Semantic search: queries the ChromaDB collection. Only chunks with distance <= distance_threshold
       are retained. Weakly-relevant or out-of-scope results above the threshold are excluded at the code level.
    """
    _, collection = get_vector_store()
    if collection.count() == 0:
        ingest_statutes()

    retrieved = []
    seen_ids = set()

    # 1. Hybrid / Section-number boost: exact section match always passes through
    sec_match = re.search(r'\b(?:section|sec)\s*([0-9]+[A-Za-z]?)\b', query, re.IGNORECASE)
    if sec_match:
        sec_num = sec_match.group(1).upper()
        exact_results = collection.get(where={"section_number": sec_num})
        if exact_results and exact_results['ids']:
            for cid, doc, meta in zip(exact_results['ids'], exact_results['documents'], exact_results['metadatas']):
                if cid not in seen_ids:
                    seen_ids.add(cid)
                    retrieved.append({
                        'content': doc,
                        'metadata': meta,
                        'distance': 0.1,  # Exact section match priority (always passes threshold)
                        'citation': f"{meta.get('short_name')} Section {meta.get('section_number')} ({meta.get('title')})"
                    })

    # 2. Semantic retrieval via Chroma query with distance filtering
    semantic_k = max(top_k, 5)
    results = collection.query(
        query_texts=[query],
        n_results=semantic_k
    )

    if results and 'documents' in results and results['documents']:
        docs = results['documents'][0]
        metas = results['metadatas'][0]
        distances = results['distances'][0] if 'distances' in results else [0.0] * len(docs)
        ids = results['ids'][0] if 'ids' in results else [f"id_{i}" for i in range(len(docs))]

        for cid, doc, meta, dist in zip(ids, docs, metas, distances):
            if cid not in seen_ids:
                # Apply distance threshold for semantic results
                if dist <= distance_threshold:
                    seen_ids.add(cid)
                    retrieved.append({
                        'content': doc,
                        'metadata': meta,
                        'distance': dist,
                        'citation': f"{meta.get('short_name')} Section {meta.get('section_number')} ({meta.get('title')})"
                    })

    return retrieved[:top_k]

if __name__ == '__main__':
    print("--- Testing Retrieval with Distance Threshold ---")
    in_scope = retrieve_sections("What is the notice period required under Section 138 of Negotiable Instruments Act?", top_k=3)
    print(f"In-scope results count: {len(in_scope)}")
    for r in in_scope:
        print(f"  {r['citation']} (dist={r['distance']})")

    out_scope = retrieve_sections("how do I get a divorce", top_k=3)
    print(f"Out-of-scope ('how do I get a divorce') results count: {len(out_scope)}")

    out_scope2 = retrieve_sections("what are traffic violation penalties", top_k=3)
    print(f"Out-of-scope ('what are traffic violation penalties') results count: {len(out_scope2)}")

    out_scope3 = retrieve_sections("how do I patent an invention", top_k=3)
    print(f"Out-of-scope ('how do I patent an invention') results count: {len(out_scope3)}")
