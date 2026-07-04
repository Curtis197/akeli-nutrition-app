import sys, os, json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from unittest.mock import patch, MagicMock
from scrapers.afroasia_us import AfroasiaUsScraper
from scrapers.base import ScrapeResult

SEARCH_RESP_AKPI = {"resources": {"results": {"products": [
    {"title": "NjangSang African Spice | AKPI | Authentic Cameroonian Spice Blend",
     "handle": "jangsang"},
]}}}

PRODUCT_RESP_AKPI = {"product": {"variants": [
    {"title": "3 oz", "price": "9.99", "grams": 100},
    {"title": "Case | 3 oz x 50 Pks", "price": "250.00", "grams": 100},
]}}

def _mock_urlopen(body):
    cm = MagicMock()
    cm.__enter__ = lambda s: s
    cm.__exit__ = MagicMock(return_value=False)
    cm.read.return_value = json.dumps(body).encode()
    return cm

def test_returns_result_for_matching_product():
    scraper = AfroasiaUsScraper()
    with patch('urllib.request.urlopen', side_effect=[
        _mock_urlopen(SEARCH_RESP_AKPI), _mock_urlopen(PRODUCT_RESP_AKPI)]):
        result = scraper.scrape(None, 'Akpi', 'Akpi')
    assert result is not None
    assert isinstance(result, ScrapeResult)
    assert result.source == 'afroasia_us'
    assert result.country_code == 'US'
    assert result.currency == 'USD'
    # cheapest variant: $9.99 / 100g -> 9.99 EUR/100g equivalent scale
    assert abs(result.price_per_100g - 9.99) < 0.01
    assert result.package_size == 100.0
    assert result.package_unit == 'g'

def test_picks_cheapest_variant_not_bulk_case():
    # Bulk case variant ($250 for 100g "case" listing) must not be selected
    # over the real single-unit variant ($9.99 for 100g).
    scraper = AfroasiaUsScraper()
    with patch('urllib.request.urlopen', side_effect=[
        _mock_urlopen(SEARCH_RESP_AKPI), _mock_urlopen(PRODUCT_RESP_AKPI)]):
        result = scraper.scrape(None, 'Akpi', 'Akpi')
    assert result is not None
    assert abs(result.price_per_100g - 9.99) < 0.01

def test_returns_none_when_no_products_match():
    # Search returns a real product, but it doesn't match the ingredient name
    # at all -> must return None, not fall back to this unrelated result.
    unrelated = {"resources": {"results": {"products": [
        {"title": "Palm Wine Vinegar 500ml", "handle": "palm-wine-vinegar"},
    ]}}}
    scraper = AfroasiaUsScraper()
    with patch('urllib.request.urlopen', return_value=_mock_urlopen(unrelated)):
        result = scraper.scrape(None, 'Dried crayfish', 'Crevettes séchées')
    assert result is None

def test_returns_none_when_search_has_no_results():
    empty = {"resources": {"results": {"products": []}}}
    scraper = AfroasiaUsScraper()
    with patch('urllib.request.urlopen', return_value=_mock_urlopen(empty)):
        assert scraper.scrape(None, 'Akpi', 'Akpi') is None

def test_returns_none_on_search_http_error():
    scraper = AfroasiaUsScraper()
    with patch('urllib.request.urlopen', side_effect=Exception("timeout")):
        assert scraper.scrape(None, 'Akpi', 'Akpi') is None

def test_returns_none_on_product_fetch_error():
    scraper = AfroasiaUsScraper()
    with patch('urllib.request.urlopen', side_effect=[
        _mock_urlopen(SEARCH_RESP_AKPI), Exception("timeout")]):
        assert scraper.scrape(None, 'Akpi', 'Akpi') is None

def test_skips_blacklisted_product():
    # Even a matching-looking title should be rejected if it hits the
    # shared non-food blacklist (defense in depth, same as google_fallback.py).
    blacklisted = {"resources": {"results": {"products": [
        {"title": "Akpi Anti-Calcaire Nettoyant Ménager", "handle": "fake-cleaner"},
    ]}}}
    scraper = AfroasiaUsScraper()
    with patch('urllib.request.urlopen', return_value=_mock_urlopen(blacklisted)):
        assert scraper.scrape(None, 'Akpi', 'Akpi') is None

def test_returns_none_when_no_variant_has_valid_weight():
    no_weight = {"product": {"variants": [
        {"title": "Sample", "price": "9.99", "grams": 0},
    ]}}
    scraper = AfroasiaUsScraper()
    with patch('urllib.request.urlopen', side_effect=[
        _mock_urlopen(SEARCH_RESP_AKPI), _mock_urlopen(no_weight)]):
        assert scraper.scrape(None, 'Akpi', 'Akpi') is None

def test_returns_none_for_ingredient_not_in_specialty_list_without_network_call():
    # This store's catalog is full of flavored/processed products that
    # incidentally contain common ingredient words (e.g. "Chicken" matched
    # "Instant Noodles with onion Chicken Flavor" during live testing).
    # Restrict this scraper to a curated specialty list — a generic
    # ingredient must short-circuit to None with zero network calls.
    scraper = AfroasiaUsScraper()
    with patch('urllib.request.urlopen') as mock_urlopen:
        result = scraper.scrape(None, 'Chicken', 'Poulet')
    assert result is None
    mock_urlopen.assert_not_called()

def test_allows_ingredients_in_specialty_list():
    scraper = AfroasiaUsScraper()
    with patch('urllib.request.urlopen', side_effect=[
        _mock_urlopen(SEARCH_RESP_AKPI), _mock_urlopen(PRODUCT_RESP_AKPI)]):
        result = scraper.scrape(None, 'Akpi', 'Akpi')
    assert result is not None
