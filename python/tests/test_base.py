import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from scrapers.base import ScrapeResult, parse_price_per_100g, parse_package_info, keyword_match

def test_scrape_result_fields():
    r = ScrapeResult(
        ingredient_id='abc', ingredient_name='Chicken', country_code='FR',
        currency='EUR', scraped_title='Filets de Poulet', price_per_100g=1.19,
        package_size=1000.0, package_unit='g', source='carrefour_fr'
    )
    assert r.ingredient_id == 'abc'
    assert r.package_unit == 'g'
    assert r.confidence == 0.0

def test_parse_price_per_kg():
    price, pkg_size, pkg_unit = parse_price_per_100g('3.49 / kg', 'Carottes vrac')
    assert abs(price - 0.349) < 0.001
    assert pkg_size == 1000.0
    assert pkg_unit == 'g'

def test_parse_price_per_100g_label():
    price, pkg_size, pkg_unit = parse_price_per_100g('£2.50 per 100g', 'Butter')
    assert abs(price - 2.50) < 0.001
    assert pkg_size == 100.0
    assert pkg_unit == 'g'

def test_parse_price_per_lb():
    price, pkg_size, pkg_unit = parse_price_per_100g('$3.98/lb', 'Beef')
    assert abs(price - 0.877) < 0.01
    assert pkg_unit == 'g'

def test_parse_price_per_unit():
    price, pkg_size, pkg_unit = parse_price_per_100g('1.30 each', 'Egg')
    assert abs(price - 1.30) < 0.001
    assert pkg_unit == 'unit'

def test_parse_price_per_litre():
    price, pkg_size, pkg_unit = parse_price_per_100g('1.20 / l', 'Coconut milk')
    assert abs(price - 0.12) < 0.001
    assert pkg_unit == 'ml'

def test_parse_package_info_kg():
    size, unit = parse_package_info('Riz Grain Long 1kg CARREFOUR')
    assert size == 1000.0
    assert unit == 'g'

def test_parse_package_info_ml():
    size, unit = parse_package_info('Lait de Coco 400ml KARA')
    assert size == 400.0
    assert unit == 'ml'

def test_parse_package_info_unit():
    size, unit = parse_package_info('Chou vert à la pièce')
    assert size == 1.0
    assert unit == 'unit'

def test_keyword_match_true_on_overlap():
    assert keyword_match('Chicken', 'Chicken Breast Fillets', {'fresh'}) is True

def test_keyword_match_false_on_no_overlap():
    assert keyword_match('Akpi', 'Great Value Paper Towels', {'great', 'value'}) is False

def test_keyword_match_false_when_query_is_all_stopwords():
    # Behavioral fix: an ingredient name that is entirely stopwords/short tokens
    # must NOT match every candidate — that reproduces the "fallback to first
    # result" bug this rewrite was built to eliminate.
    assert keyword_match('de la', 'Anything At All', {'de', 'la'}) is False
