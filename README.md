# Vakil AI ⚖️ — Legal Q&A Assistant for Indian MSMEs

An authoritative, statute-grounded legal assistant for Indian Micro, Small, and Medium Enterprises (MSMEs) and commercial business owners. Built with a two-layer RAG architecture and grounded on verbatim central statutes directly fetched from the official **India Code portal** (`indiacode.gov.in`).

---

## 🏛️ Ingested Statutes & Scope

All legal data is sourced directly from India Code REST API endpoints and stored verbatim with official government UUIDs, handles, and section metadata (documented in `data/statutes/sources.json`):

1. **Micro, Small and Medium Enterprises Development Act, 2006 (MSMED Act)**
   - Complete statutory coverage (Sections 1–32)
   - Mandatory payment timelines (Section 15)
   - Compound interest at 3x RBI bank rate with monthly rests on delayed payments (Section 16)
   - Recovery of amount due (Section 17) & MSEFC reference (Section 18)

2. **The Negotiable Instruments Act, 1881 (NI Act)**
   - Cheque dishonour for insufficiency of funds (Section 138)
   - Presumption in favour of holder (Section 139)
   - Offences by companies (Section 141)
   - Cognizance & limitation timelines (Section 142)
   - Interim compensation (Section 143A) & compounding of offences (Section 147)

3. **The Central Goods and Services Tax Act, 2017 (CGST Act)**
   - Self-assessment & provisional assessment (Sections 59, 60)
   - Scrutiny of returns & 30-day explanation window (Section 61)
   - Tax determination & notices (Sections 73, 74, 75)
   - Penalties for offences & detention in transit (Sections 122, 125, 129)

4. **The Indian Contract Act, 1872**
   - Essential contract formation, consideration, and validity (Sections 1–30)
   - Compensation for breach of contract & liquidated damages (Sections 73, 74, 75)

---

## 🛡️ Two-Layer Out-of-Scope Defense

To guarantee legal accuracy and avoid hallucinated advice outside MSME commercial law:

1. **Layer 1 — Deterministic Distance Threshold Filter (`src/vector_store.py`)**:
   - Semantic retrieval using local ChromaDB (`all-MiniLM-L6-v2`).
   - Cutoff threshold: **`distance <= 1.10`**. Any weakly-relevant or completely out-of-scope query (e.g. divorce, traffic penalties, patents, adverse possession) drops to 0 retrieved chunks at the code level, triggering an immediate refusal without calling the LLM.
   - Exact section-number boost (`Section 138`, `Sec 16`) always passes through with priority.

2. **Layer 2 — Grounded Generation & Policy Enforcement (`src/generator.py`)**:
   - Queries evaluated by Gemini (`gemini-3.5-flash-lite`).
   - Strict system prompt requiring exact statutory citations (`[Act Name, Section X - Title]`).
   - Rejection policy: If retrieved text does not govern the subject matter, the model explicitly declines.
   - Mandatory disclaimer appended to every answer:
     > *"This is legal information, not legal advice. Consult a qualified lawyer for your specific situation."*

---

## 🚀 Quickstart Guide

### 1. Prerequisites
- Python 3.10+ (tested on Python 3.14)
- Git

### 2. Installation
Clone the repository and install dependencies:
```bash
git clone https://github.com/abhinavtiwary15/vakil_ai.git
cd vakil_ai
pip install -r requirements.txt
```

### 3. Environment Configuration
Copy the example environment file and add your Google Gemini API key:
```bash
cp .env.example .env
```
Edit `.env`:
```env
GEMINI_API_KEY=your_actual_gemini_api_key
```

### 4. Vector Store Generation
`chroma_db/` is git-ignored and can be indexed locally in seconds from the raw statute JSON files:
```bash
python -m src.vector_store
```

### 5. Launch Web UI
Run the interactive Streamlit chat interface:
```bash
streamlit run app.py
```

### 6. Run Automated Test Suite
Execute the 8-test verification suite covering retrieval precision, section boosting, code-level thresholding, and out-of-scope rejection:
```bash
python -m pytest tests/test_rag.py -v
```

---

## 📂 Project Architecture

```text
vakil_ai/
├── app.py                     # Streamlit web application
├── requirements.txt           # Python package dependencies
├── .env.example               # Environment variables template
├── .gitignore                 # Git ignore rules (secrets, chroma_db, caches)
├── README.md                  # Project documentation
├── data/
│   └── statutes/
│       ├── sources.json       # Authoritative India Code metadata manifest
│       ├── msmed_act_2006.json
│       ├── negotiable_instruments_act_1881.json
│       ├── cgst_act_2017.json
│       └── indian_contract_act_1872.json
├── src/
│   ├── __init__.py
│   ├── fetcher.py             # Official India Code DSpace API scraper
│   ├── chunker.py             # Section-aware statutory text chunker
│   ├── vector_store.py        # ChromaDB persistent vector store & hybrid retriever
│   └── generator.py           # Grounded Gemini answer generator & citation engine
└── tests/
    ├── __init__.py
    └── test_rag.py            # Automated test suite (8 tests)
```

---

## ⚖️ Disclaimer
*This application provides legal information for educational and informational purposes only. It does not constitute formal legal advice. Consult a qualified advocate or legal professional for counsel regarding specific legal issues.*
