import sys, os, json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from unittest.mock import patch, MagicMock
from scrapers.openfoodfacts import OpenFoodFactsScraper
from scrapers.base import ScrapeResult

MOCK_RESP = {"items": [
    {"product": {"product_name": "Chicken breast"}, "price": 11.90, "currency": "EUR", "location_country": "FR"},
    {"product": {"product_name": "Chicken breast"}, "price": 12.50, "currency": "EUR", "location_country": "FR"},
    {"product": {"product_name": "Filets de poulet"}, "price": 13.00, "currency": "EUR", "location_country": "FR"},
]}

def _mock_urlopen(body):
    cm = MagicMock()
    cm.__enter__ = lambda s: s
    cm.__exit__ = MagicMock(return_value=False)
    cm.read.return_value = json.dumps(body).encode()
    return cm

def test_returns_median_price():
    scraper = OpenFoodFactsScraper(country_code='FR', currency='EUR')
    with patch('urllib.request.urlopen', return_value=_mock_urlopen(MOCK_RESP)):
        result = scraper.scrape(None, 'Chicken', 'Poulet')
    assert result is not None
    assert isinstance(result, ScrapeResult)
    # Prices are per kg [11.90, 12.50, 13.00]; median=12.50; /10 = 1.25
    assert abs(result.price_per_100g - 1.25) < 0.01
    assert result.source == 'openfoodfacts'
    assert result.country_code == 'FR'
    assert result.currency == 'EUR'

def test_returns_none_when_fewer_than_3_results():
    few = {"items": [
        {"product": {"product_name": "X"}, "price": 1.0, "currency": "EUR", "location_country": "FR"},
    ]}
    scraper = OpenFoodFactsScraper(country_code='FR', currency='EUR')
    with patch('urllib.request.urlopen', return_value=_mock_urlopen(few)):
        assert scraper.scrape(None, 'Chicken', 'Poulet') is None

def test_returns_none_on_http_error():
    scraper = OpenFoodFactsScraper(country_code='FR', currency='EUR')
    with patch('urllib.request.urlopen', side_effect=Exception("timeout")):
        assert scraper.scrape(None, 'Chicken', 'Poulet') is None
