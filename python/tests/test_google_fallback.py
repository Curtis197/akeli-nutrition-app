import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from unittest.mock import MagicMock
from scrapers.google_fallback import GoogleFallbackScraper

def _page(products):
    p = MagicMock()
    p.goto = MagicMock(); p.wait_for_timeout = MagicMock()
    p.evaluate.return_value = products
    return p

def test_returns_result_for_specialty_ingredient():
    result = GoogleFallbackScraper('FR', 'EUR').scrape(
        _page([{'title': 'Akpi seeds 200g afrishop', 'priceStr': '4.99', 'url': 'https://afrishop.fr/akpi'}]),
        'Akpi', 'Akpi')
    assert result is not None
    assert result.source == 'google_fallback'
    assert result.country_code == 'FR'
    assert result.price_per_100g > 0

def test_skips_non_food_hits():
    result = GoogleFallbackScraper('FR', 'EUR').scrape(
        _page([{'title': 'Nettoyant Anti-Calcaire ANTIKAL', 'priceStr': '3.50', 'url': 'https://shop.fr/clean'}]),
        'Akpi', 'Akpi')
    assert result is None

def test_returns_none_on_empty():
    assert GoogleFallbackScraper('FR', 'EUR').scrape(_page([]), 'Akpi', 'Akpi') is None

def test_returns_none_on_error():
    p = MagicMock(); p.goto.side_effect = Exception("blocked")
    assert GoogleFallbackScraper('FR', 'EUR').scrape(p, 'Akpi', 'Akpi') is None
