import sys, os
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

def test_cascade_falls_back_to_google_on_reject():
    google = MagicMock(scrape=MagicMock(return_value=_result('google_fallback')))
    with patch.dict('orchestrator.OFF_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}), \
         patch.dict('orchestrator.RETAILER_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=_result()))}), \
         patch.dict('orchestrator.GOOGLE_SCRAPERS', {'FR': google}), \
         patch('orchestrator.validate', side_effect=[
             ValidationResult('REJECT', 'bad'), ValidationResult('PASS', 'ok')]):
        result, vr = orchestrator.run_cascade(MagicMock(), None, _ING, 'FR')
    assert result.source == 'google_fallback'

def test_cascade_returns_none_when_all_fail():
    with patch.dict('orchestrator.OFF_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}), \
         patch.dict('orchestrator.RETAILER_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}), \
         patch.dict('orchestrator.GOOGLE_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}):
        result, vr = orchestrator.run_cascade(MagicMock(), None, _ING, 'FR')
    assert result is None and vr is None
