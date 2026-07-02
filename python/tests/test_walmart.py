import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from unittest.mock import MagicMock
from scrapers.walmart_us import WalmartUsScraper
from scrapers.walmart_ca import WalmartCaScraper

def _page(products):
    p = MagicMock()
    p.goto = MagicMock(); p.wait_for_timeout = MagicMock()
    p.evaluate.return_value = products
    return p

def test_walmart_us_returns_result():
    result = WalmartUsScraper().scrape(
        _page([{'title': 'Great Value Chicken Breast', 'priceStr': '$3.98/lb'}]),
        'Chicken', 'Poulet')
    assert result is not None
    assert result.country_code == 'US'
    assert result.currency == 'USD'
    assert abs(result.price_per_100g - 0.877) < 0.01   # 3.98 / 4.536
    assert result.source == 'walmart_us'

def test_walmart_us_returns_none_on_empty():
    assert WalmartUsScraper().scrape(_page([]), 'Akpi', 'Akpi') is None

def test_walmart_us_returns_none_on_error():
    p = MagicMock(); p.goto.side_effect = Exception("bot detected")
    assert WalmartUsScraper().scrape(p, 'Chicken', 'Poulet') is None

def test_walmart_ca_returns_result():
    result = WalmartCaScraper().scrape(
        _page([{'title': 'Chicken Breast Boneless', 'priceStr': '$12.98/kg'}]),
        'Chicken', 'Poulet')
    assert result is not None
    assert result.country_code == 'CA'
    assert result.currency == 'CAD'
    assert abs(result.price_per_100g - 1.298) < 0.01
    assert result.source == 'walmart_ca'

def test_walmart_ca_returns_none_on_empty():
    assert WalmartCaScraper().scrape(_page([]), 'Akpi', 'Akpi') is None
