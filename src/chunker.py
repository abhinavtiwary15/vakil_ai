"""
Section-aware chunker for Vakil AI.
Chunks Indian statutes while preserving full section semantics and hierarchy.
Never splits a section down the middle unless it exceeds max character limit.
"""

import os
import json
import re
from typing import List, Dict, Any

def chunk_statute_section(section: Dict[str, Any], max_chunk_chars: int = 1800) -> List[Dict[str, Any]]:
    act_name = section.get('act_name', '')
    short_name = section.get('short_name', '')
    act_id = section.get('act_id', '')
    sec_num = section.get('section_number', '')
    title = section.get('title', '')
    text = section.get('verbatim_text', '').strip()
    source_url = section.get('source_url', '')

    header = f"[{short_name} | Section {sec_num} - {title}]"

    # If text is within comfortable size, keep as single atomic chunk
    if len(text) <= max_chunk_chars:
        return [{
            'id': f"{act_id}_sec_{sec_num}_part_1",
            'text': f"{header}\n{text}",
            'metadata': {
                'act_name': act_name,
                'short_name': short_name,
                'act_id': act_id,
                'section_number': str(sec_num),
                'title': title,
                'source_url': source_url,
                'part': 1,
                'total_parts': 1
            }
        }]

    # For longer sections, split along sub-clauses / provisos / explanations
    # Split on double newline or subsection numbering like "(1)", "(2)", "Provided that", "Explanation"
    paragraphs = re.split(r'\n\s*\n', text)
    chunks = []
    current_paragraphs = []
    current_len = 0

    for para in paragraphs:
        para = para.strip()
        if not para:
            continue
        if current_len + len(para) > max_chunk_chars and current_paragraphs:
            part_num = len(chunks) + 1
            chunk_content = "\n\n".join(current_paragraphs)
            chunks.append({
                'id': f"{act_id}_sec_{sec_num}_part_{part_num}",
                'text': f"{header} (Part {part_num})\n{chunk_content}",
                'metadata': {
                    'act_name': act_name,
                    'short_name': short_name,
                    'act_id': act_id,
                    'section_number': str(sec_num),
                    'title': title,
                    'source_url': source_url,
                    'part': part_num
                }
            })
            current_paragraphs = [para]
            current_len = len(para)
        else:
            current_paragraphs.append(para)
            current_len += len(para)

    if current_paragraphs:
        part_num = len(chunks) + 1
        chunk_content = "\n\n".join(current_paragraphs)
        chunks.append({
            'id': f"{act_id}_sec_{sec_num}_part_{part_num}",
            'text': f"{header} (Part {part_num})\n{chunk_content}",
            'metadata': {
                'act_name': act_name,
                'short_name': short_name,
                'act_id': act_id,
                'section_number': str(sec_num),
                'title': title,
                'source_url': source_url,
                'part': part_num
            }
        })

    total_parts = len(chunks)
    for c in chunks:
        c['metadata']['total_parts'] = total_parts

    return chunks

def process_all_statutes(statutes_dir: str = 'data/statutes') -> List[Dict[str, Any]]:
    manifest_path = os.path.join(statutes_dir, 'sources.json')
    if not os.path.exists(manifest_path):
        raise FileNotFoundError(f"Manifest not found at {manifest_path}")

    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    all_chunks = []
    for act_key, act_meta in manifest.get('acts', {}).items():
        act_file = os.path.join(statutes_dir, act_meta['file'])
        if not os.path.exists(act_file):
            continue
        with open(act_file, 'r', encoding='utf-8') as f:
            sections = json.load(f)
        for sec_num, sec_data in sections.items():
            chunks = chunk_statute_section(sec_data)
            all_chunks.extend(chunks)

    print(f"[+] Total section-aware chunks created: {len(all_chunks)}")
    return all_chunks

if __name__ == '__main__':
    chunks = process_all_statutes()
    print("Sample Chunk 1:")
    print(chunks[0]['text'][:300])
