import sys, os, json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from unittest.mock import patch, MagicMock
from scrapers.base import ScrapeResult
from validator import ValidationResult
import orchestrator

def _result(source='carrefour_fr'):
    return ScrapeResult(
        ingredient_id='id1', ingredient_name='Chicken', country_code='FR',
        currency='EUR', scraped_title='Filets de Poulet', price_per_100g=1.19,
        package_size=1000.0, package_unit='g', source=source)

_ING = {'id': 'id1', 'name': 'Chicken', 'name_fr': 'Poulet', 'category': 'meat'}

def test_cascade_uses_off_first():
    off = MagicMock(scrape=MagicMock(return_value=_result('openfoodfacts')))
    with patch.dict('orchestrator.OFF_SCRAPERS', {'FR': off}), \
         patch('orchestrator.validate', return_value=ValidationResult('PASS', 'ok')):
        result, vr = orchestrator.run_cascade(None, None, _ING, 'FR')
    assert result.source == 'openfoodfacts'

def test_cascade_falls_back_to_retailer_when_off_none():
    retailer = MagicMock(scrape=MagicMock(return_value=_result('carrefour_fr')))
    with patch.dict('orchestrator.OFF_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}), \
         patch.dict('orchestrator.RETAILER_SCRAPERS', {'FR': retailer}), \
         patch('orchestrator.validate', return_value=ValidationResult('PASS', 'ok')):
        result, vr = orchestrator.run_cascade(MagicMock(), None, _ING, 'FR')
    assert result.source == 'carrefour_fr'

def test_cascade_falls_back_to_specialty_source_when_retailer_none():
    specialty = MagicMock(scrape=MagicMock(return_value=_result('afroasia_us')))
    with patch.dict('orchestrator.OFF_SCRAPERS', {'US': MagicMock(scrape=MagicMock(return_value=None))}), \
         patch.dict('orchestrator.RETAILER_SCRAPERS', {'US': MagicMock(scrape=MagicMock(return_value=None))}), \
         patch.dict('orchestrator.SPECIALTY_SCRAPERS', {'US': specialty}), \
         patch('orchestrator.validate', return_value=ValidationResult('PASS', 'ok')):
        result, vr = orchestrator.run_cascade(MagicMock(), None, _ING, 'US')
    assert result.source == 'afroasia_us'

def test_cascade_falls_back_to_google_on_reject():
    google = MagicMock(scrape=MagicMock(return_value=_result('google_fallback')))
    with patch.dict('orchestrator.OFF_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}), \
         patch.dict('orchestrator.RETAILER_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=_result()))}), \
         patch.dict('orchestrator.SPECIALTY_SCRAPERS', {}), \
         patch.dict('orchestrator.GOOGLE_SCRAPERS', {'FR': google}), \
         patch('orchestrator.validate', side_effect=[
             ValidationResult('REJECT', 'bad'), ValidationResult('PASS', 'ok')]):
        result, vr = orchestrator.run_cascade(MagicMock(), None, _ING, 'FR')
    assert result.source == 'google_fallback'

def test_cascade_returns_none_when_all_fail():
    with patch.dict('orchestrator.OFF_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}), \
         patch.dict('orchestrator.RETAILER_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}), \
         patch.dict('orchestrator.SPECIALTY_SCRAPERS', {}), \
         patch.dict('orchestrator.GOOGLE_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}):
        result, vr = orchestrator.run_cascade(MagicMock(), None, _ING, 'FR')
    assert result is None and vr is None

def test_main_continues_and_logs_review_entry_when_run_cascade_raises(tmp_path, monkeypatch):
    """An unexpected exception from run_cascade must not crash the batch loop —
    it should be caught, recorded in review_queue.json, and the loop should
    continue to the next ingredient. Also verifies JSON files are still
    written (defense-in-depth for Finding 1)."""
    monkeypatch.chdir(tmp_path)

    ingredients = [
        {'id': 'id1', 'name': 'Chicken', 'name_fr': 'Poulet', 'category': 'meat'},
        {'id': 'id2', 'name': 'Rice', 'name_fr': 'Riz', 'category': 'grain'},
    ]

    # First call raises an unanticipated exception, second call returns a clean UNFOUND.
    def fake_run_cascade(page, context, ing, code):
        if ing['id'] == 'id1':
            raise KeyError('boom')
        return None, None

    fake_page = MagicMock()
    fake_ctx = MagicMock()
    fake_browser = MagicMock(new_context=MagicMock(return_value=fake_ctx))
    fake_ctx.new_page = MagicMock(return_value=fake_page)

    fake_p = MagicMock()
    fake_p.chromium.launch = MagicMock(return_value=fake_browser)

    fake_playwright_cm = MagicMock()
    fake_playwright_cm.__enter__ = MagicMock(return_value=fake_p)
    fake_playwright_cm.__exit__ = MagicMock(return_value=False)

    with patch('orchestrator.sync_playwright', return_value=fake_playwright_cm), \
         patch('orchestrator._build_scrapers'), \
         patch('orchestrator.get_ingredients', return_value=ingredients), \
         patch('orchestrator.run_cascade', side_effect=fake_run_cascade), \
         patch('orchestrator.trigger_recipe_recalc'), \
         patch('sys.argv', ['orchestrator.py', '--countries', 'FR', '--dry-run', '--delay', '0']):
        orchestrator.main()

    with open('review_queue.json', encoding='utf-8') as f:
        review = json.load(f)

    # id1/FR should be recorded as an unexpected-exception review entry,
    # and id2/FR should still have been processed (loop did not stop).
    assert any(r['ingredient_id'] == 'id1' and r['last_source'] == 'unexpected_exception'
               and 'boom' in r['reject_reason'] for r in review)
    assert any(r['ingredient_id'] == 'id2' and r['last_source'] == 'all_failed' for r in review)

    with open('scraped_prices.json', encoding='utf-8') as f:
        scraped = json.load(f)
    assert scraped == []


def test_main_exits_before_browser_when_get_ingredients_returns_empty(tmp_path, monkeypatch):
    """Finding 2: a transient DB failure (get_ingredients() returning []) must
    not fall through into the Playwright block and overwrite existing output
    files with empty lists. Pre-seed both output files with real content and
    confirm they are untouched after main() exits early."""
    monkeypatch.chdir(tmp_path)

    existing_scraped = [{'ingredient_id': 'keep-me'}]
    existing_review = [{'ingredient_id': 'keep-me-too', 'country_code': 'FR'}]
    with open('scraped_prices.json', 'w', encoding='utf-8') as f:
        json.dump(existing_scraped, f)
    with open('review_queue.json', 'w', encoding='utf-8') as f:
        json.dump(existing_review, f)

    with patch('orchestrator.sync_playwright') as mock_playwright, \
         patch('orchestrator._build_scrapers'), \
         patch('orchestrator.get_ingredients', return_value=[]), \
         patch('sys.argv', ['orchestrator.py', '--countries', 'FR', '--dry-run', '--delay', '0']):
        try:
            orchestrator.main()
            raised = False
        except SystemExit as e:
            raised = True
            exit_code = e.code

    assert raised and exit_code != 0
    # Playwright must never have been entered.
    mock_playwright.assert_not_called()

    with open('scraped_prices.json', encoding='utf-8') as f:
        assert json.load(f) == existing_scraped
    with open('review_queue.json', encoding='utf-8') as f:
        assert json.load(f) == existing_review


def test_retry_review_category_survives_round_trip(tmp_path, monkeypatch):
    """Finding 1: category must survive original write -> review_queue.json
    -> --retry-review read -> synthetic ingredient dict -> run_cascade, so
    revalidation uses the correct (narrow) price-sanity band instead of
    silently falling back to the wide 'default' band."""
    monkeypatch.chdir(tmp_path)

    queue = [
        {'ingredient_id': 'id1', 'ingredient_name': 'Cumin', 'name_fr': 'Cumin',
         'country_code': 'FR', 'category': 'spice',
         'last_source': 'all_failed', 'reject_reason': 'x'},
    ]
    with open('review_queue.json', 'w', encoding='utf-8') as f:
        json.dump(queue, f)

    seen_categories = []

    def fake_run_cascade(page, context, ing, code):
        seen_categories.append(ing.get('category'))
        return None, None

    fake_page = MagicMock()
    fake_ctx = MagicMock()
    fake_browser = MagicMock(new_context=MagicMock(return_value=fake_ctx))
    fake_ctx.new_page = MagicMock(return_value=fake_page)
    fake_p = MagicMock()
    fake_p.chromium.launch = MagicMock(return_value=fake_browser)
    fake_playwright_cm = MagicMock()
    fake_playwright_cm.__enter__ = MagicMock(return_value=fake_p)
    fake_playwright_cm.__exit__ = MagicMock(return_value=False)

    with patch('orchestrator.sync_playwright', return_value=fake_playwright_cm), \
         patch('orchestrator._build_scrapers'), \
         patch('orchestrator.run_cascade', side_effect=fake_run_cascade), \
         patch('orchestrator.trigger_recipe_recalc'), \
         patch('sys.argv', ['orchestrator.py', '--retry-review', '--dry-run', '--delay', '0']):
        orchestrator.main()

    assert seen_categories == ['spice']
