import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from unittest.mock import MagicMock
from scrapers.carrefour_fr import CarrefourFrScraper
from scrapers.base import ScrapeResult

def _page(products):
    p = MagicMock()
    p.goto = MagicMock()
    p.wait_for_timeout = MagicMock()
    p.locator.return_value.count.return_value = 0
    p.evaluate.return_value = products
    return p

def test_returns_result_for_matching_product():
    page = _page([{'title': 'Filets de Poulet', 'priceStr': '11,90 € / kg'}])
    result = CarrefourFrScraper().scrape(page, 'Chicken', 'Poulet')
    assert result is not None
    assert result.country_code == 'FR'
    assert result.currency == 'EUR'
    assert abs(result.price_per_100g - 1.19) < 0.01
    assert result.package_unit == 'g'
    assert result.source == 'carrefour_fr'

def test_returns_none_when_no_products():
    result = CarrefourFrScraper().scrape(_page([]), 'Akpi', 'Akpi')
    assert result is None

def test_returns_none_when_first_result_is_unrelated():
    # v1 failure mode: search "Akpi" returned a descaler as first hit.
    # No keyword match against the French name → scraper must return None,
    # NOT fall back to the first result.
    page = _page([{'title': 'Nettoyant Ménager Anti-Calcaire ANTIKAL',
                   'priceStr': '3,50 € / l'}])
    result = CarrefourFrScraper().scrape(page, 'Akpi', 'Akpi')
    assert result is None

def test_parses_per_100g_price():
    page = _page([{'title': 'Poivre Noir Moulu CARREFOUR', 'priceStr': '2,36 € / 100g'}])
    result = CarrefourFrScraper().scrape(page, 'Black pepper', 'Poivre noir')
    assert result is not None
    assert abs(result.price_per_100g - 2.36) < 0.01

def test_returns_none_on_page_error():
    p = MagicMock()
    p.goto.side_effect = Exception("timeout")
    assert CarrefourFrScraper().scrape(p, 'Chicken', 'Poulet') is None
