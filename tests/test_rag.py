"""
Automated Test Suite for Vakil AI.
Tests:
1. Retrieval accuracy for key statutory sections:
   - MSMED Act Sec 16 (delayed payment interest)
   - NI Act Sec 138 (cheque dishonour)
   - CGST Act Sec 61 (scrutiny of returns)
   - Indian Contract Act Sec 73 (compensation for breach)
2. Exact section number boost bypasses distance threshold.
3. Code-enforced distance threshold drops out-of-scope queries (Layer 1).
4. Full two-layer out-of-scope rejection (code threshold + LLM judgment).
5. Grounded generation citation and disclaimer compliance.
"""

import pytest
from src.vector_store import retrieve_sections, DEFAULT_DISTANCE_THRESHOLD
from src.generator import generate_answer, DISCLAIMER

def test_retrieval_msmed_section_16():
    results = retrieve_sections("What interest rate is payable on delayed payments to MSME?", top_k=3)
    sections = [r['metadata'].get('section_number') for r in results]
    acts = [r['metadata'].get('short_name') for r in results]
    assert '16' in sections
    assert any('MSMED' in a for a in acts)

def test_retrieval_ni_act_section_138():
    results = retrieve_sections("What happens when a cheque is bounced due to insufficient funds?", top_k=3)
    sections = [r['metadata'].get('section_number') for r in results]
    acts = [r['metadata'].get('short_name') for r in results]
    assert '138' in sections
    assert any('Negotiable Instruments' in a for a in acts)

def test_retrieval_cgst_act_section_61():
    results = retrieve_sections("Can the tax officer scrutinize my GST return and ask for explanations?", top_k=3)
    sections = [r['metadata'].get('section_number') for r in results]
    acts = [r['metadata'].get('short_name') for r in results]
    assert '61' in sections
    assert any('CGST' in a for a in acts)

def test_retrieval_contract_act_section_73():
    results = retrieve_sections("Can I claim compensation for loss caused by breach of contract?", top_k=3)
    sections = [r['metadata'].get('section_number') for r in results]
    acts = [r['metadata'].get('short_name') for r in results]
    assert '73' in sections
    assert any('Contract' in a for a in acts)

def test_section_boost_always_passes():
    """Exact section mention should always pass through even if distance threshold is very strict."""
    results = retrieve_sections("What does section 138 say?", top_k=3, distance_threshold=0.2)
    assert len(results) > 0
    assert results[0]['metadata'].get('section_number') == '138'

def test_code_level_threshold_rejection():
    """Confirms Layer 1 defense: out-of-scope queries return 0 chunks from vector store."""
    unrelated_queries = [
        "how do I get a divorce",
        "what are traffic violation penalties",
        "how do I patent an invention",
        "How do I claim adverse possession of an ancestral property in Mumbai?"
    ]
    for q in unrelated_queries:
        chunks = retrieve_sections(q, top_k=3)
        assert len(chunks) == 0, f"Query '{q}' should have returned 0 chunks, but returned {len(chunks)}"

def test_out_of_scope_rejection():
    """Confirms end-to-end rejection for various unrelated legal questions."""
    unrelated_queries = [
        "how do I get a divorce",
        "what are traffic violation penalties",
        "how do I patent an invention",
        "rules for filing a mutual consent divorce under Hindu Marriage Act"
    ]
    for q in unrelated_queries:
        res = generate_answer(q, top_k=3)
        assert res['is_out_of_scope'] is True
        assert "restricted to the MSMED Act 2006, CGST Act 2017" in res['answer']
        assert DISCLAIMER in res['answer']

def test_grounded_answer_structure():
    query = "What is the notice period required under Section 138 of Negotiable Instruments Act?"
    res = generate_answer(query, top_k=3)
    assert res['is_out_of_scope'] is False
    assert len(res['citations']) > 0
    assert DISCLAIMER in res['answer']
    assert any(x in res['answer'] for x in ["30 days", "thirty days", "15 days", "fifteen days"])
