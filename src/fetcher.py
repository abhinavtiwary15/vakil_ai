"""
Statute fetcher module for Vakil AI.
Fetches verbatim text of central statutes directly from official India Code (indiacode.gov.in) DSpace REST API.
No synthesis, no paraphrasing, strictly official statutory text.
"""

import os
import json
import time
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timezone

BASE_API = 'https://indiacode.gov.in/server/api'
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

ACT_CONFIG = {
    'msmed_act_2006': {
        'act_id': 'AC_CEN_46_77_00002_200627_1517807324919',
        'act_name': 'The Micro, Small and Medium Enterprises Development Act, 2006',
        'short_name': 'MSMED Act, 2006',
        'sections': None  # Fetch all available sections (1-32)
    },
    'negotiable_instruments_act_1881': {
        'act_id': 'AC_CEN_2_33_00042_00042_1523271998701',
        'act_name': 'The Negotiable Instruments Act, 1881',
        'short_name': 'Negotiable Instruments Act, 1881',
        'sections': ['138', '139', '140', '141', '142', '143', '143A', '147', '148']
    },
    'cgst_act_2017': {
        'act_id': 'AC_CEN_2_2_00042_201712_1517807328102',
        'act_name': 'The Central Goods and Services Tax Act, 2017',
        'short_name': 'CGST Act, 2017',
        'sections': ['59', '60', '61', '62', '63', '64', '73', '74', '75', '122', '123', '125', '129', '130']
    },
    'indian_contract_act_1872': {
        'act_id': 'AC_CEN_3_20_00035_187209_1523268996428',
        'act_name': 'The Indian Contract Act, 1872',
        'short_name': 'Indian Contract Act, 1872',
        'sections': [str(i) for i in range(1, 31)] + ['73', '74', '75']
    }
}

def clean_html(html_text: str) -> str:
    if not html_text:
        return ''
    soup = BeautifulSoup(html_text, 'html.parser')
    text = soup.get_text(separator='\n')
    lines = [line.strip() for line in text.splitlines()]
    clean_lines = []
    prev_blank = False
    for line in lines:
        if not line:
            if not prev_blank:
                clean_lines.append('')
                prev_blank = True
        else:
            clean_lines.append(line)
            prev_blank = False
    return '\n'.join(clean_lines).strip()

def fetch_act_sections(act_key: str, cfg: dict):
    act_id = cfg['act_id']
    act_name = cfg['act_name']
    short_name = cfg['short_name']
    target_sections = set(cfg['sections']) if cfg['sections'] else None

    print(f'[*] Fetching {short_name} (Act ID: {act_id})...')
    page = 0
    sections_data = {}
    total_pages = 1

    while page < total_pages:
        url = f'{BASE_API}/discover/search/objects?f.act_id={act_id},equals&page={page}&size=100'
        try:
            resp = requests.get(url, headers=HEADERS, timeout=25)
            resp.raise_for_status()
            data = resp.json()
            search_res = data.get('_embedded', {}).get('searchResult', {})
            total_pages = search_res.get('page', {}).get('totalPages', 1)
            objs = search_res.get('_embedded', {}).get('objects', [])

            for o in objs:
                item = o.get('_embedded', {}).get('indexableObject', {})
                meta = item.get('metadata', {})
                sec_num = meta.get('dc.identifier.section_number', [{}])[0].get('value', '').strip()
                title = meta.get('dc.title', [{}])[0].get('value', '').strip()
                note_html = meta.get('dc.identifier.section_page_note', [{}])[0].get('value', '')

                if not sec_num or not note_html:
                    continue

                if target_sections and sec_num not in target_sections:
                    continue

                if sec_num in sections_data:
                    continue

                handle = item.get('handle', '')
                uuid = item.get('uuid', '')
                clean_text = clean_html(note_html)

                sections_data[sec_num] = {
                    'act_name': act_name,
                    'short_name': short_name,
                    'act_id': act_id,
                    'section_number': sec_num,
                    'title': title,
                    'verbatim_text': clean_text,
                    'handle': handle,
                    'uuid': uuid,
                    'source_url': f'https://indiacode.gov.in/handle/{handle}' if handle else f'https://indiacode.gov.in/server/api/core/items/{uuid}',
                    'fetched_at': datetime.now(timezone.utc).isoformat()
                }

            page += 1
            if target_sections and all(s in sections_data for s in target_sections):
                break

        except Exception as e:
            print(f'Error fetching page {page} for {act_key}: {e}')
            break

    print(f'  [+] Finished {short_name}: {len(sections_data)} sections fetched.')
    return sections_data

def run():
    out_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'data', 'statutes')
    os.makedirs(out_dir, exist_ok=True)
    manifest = {
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'source_portal': 'https://indiacode.gov.in',
        'api_base': BASE_API,
        'acts': {}
    }

    for act_key, cfg in ACT_CONFIG.items():
        sections = fetch_act_sections(act_key, cfg)
        out_path = os.path.join(out_dir, f'{act_key}.json')
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump(sections, f, indent=2, ensure_ascii=False)

        manifest['acts'][act_key] = {
            'act_name': cfg['act_name'],
            'short_name': cfg['short_name'],
            'act_id': cfg['act_id'],
            'section_count': len(sections),
            'file': f'{act_key}.json',
            'sections_captured': sorted(sections.keys(), key=lambda x: int(x) if x.isdigit() else 999)
        }

    manifest_path = os.path.join(out_dir, 'sources.json')
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    print(f'\n[SUCCESS] Manifest written to {manifest_path}')

if __name__ == '__main__':
    run()
