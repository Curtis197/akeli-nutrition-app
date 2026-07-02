import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from unittest.mock import MagicMock
from scrapers.tesco_gb import TescoGbScraper

def _page(products):
    p = MagicMock()
    p.goto = MagicMock(); p.wait_for_timeout = MagicMock()
    p.evaluate.return_value = products
    return p

def test_returns_result_for_chicken():
    result = TescoGbScraper().scrape(
        _page([{'title': 'Chicken Breast Fillets', 'priceStr': '£8.00/kg'}]),
        'Chicken', 'Poulet')
    assert result is not None
    assert result.country_code == 'GB'
    assert result.currency == 'GBP'
    assert abs(result.price_per_100g - 0.80) < 0.01
    assert result.source == 'tesco_gb'

def test_returns_result_per_100g():
    result = TescoGbScraper().scrape(
        _page([{'title': 'Black Pepper Ground', 'priceStr': '£1.80 per 100g'}]),
        'Black pepper', 'Poivre')
    assert result is not None
    assert abs(result.price_per_100g - 1.80) < 0.01

def test_returns_none_on_empty():
    assert TescoGbScraper().scrape(_page([]), 'Akpi', 'Akpi') is None

def test_returns_none_on_error():
    p = MagicMock(); p.goto.side_effect = Exception("blocked")
    assert TescoGbScraper().scrape(p, 'Chicken', 'Poulet') is None
