import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from scrapers.base import ScrapeResult
from validator import validate, ValidationResult

def _r(**kw):
    base = dict(ingredient_id='id1', ingredient_name='Chicken', country_code='FR',
                currency='EUR', scraped_title='Filets de Poulet', price_per_100g=1.19,
                package_size=1000.0, package_unit='g', source='carrefour_fr')
    base.update(kw)
    return ScrapeResult(**base)

# Check 1 — non-food blacklist
def test_rejects_cleaning_product():
    r = _r(ingredient_name='Akpi', scraped_title='Nettoyant Ménager Anti-Calcaire ANTIKAL',
            price_per_100g=0.54, package_unit='ml')
    vr = validate(r, 'Akpi', 'spice')
    assert vr.verdict == 'REJECT'
    assert 'non-food' in vr.reason.lower()

def test_rejects_cat_food():
    r = _r(ingredient_name='Kale Sukuma',
            scraped_title='Croquettes pour Chat Senior ULTIMA', price_per_100g=0.70)
    vr = validate(r, 'Kale Sukuma', 'vegetable')
    assert vr.verdict == 'REJECT'

def test_rejects_cosmetics():
    r = _r(ingredient_name='Suya spice powder',
            scraped_title='Poudre Matifiante Stay Matte RIMMEL',
            price_per_100g=67.5, package_unit='ml')
    vr = validate(r, 'Suya spice powder', 'spice')
    assert vr.verdict == 'REJECT'

# Check 2 — keyword overlap with EN→FR translation
def test_pass_english_to_french_translation():
    r = _r(ingredient_name='Chicken', scraped_title='Filets de Poulet', price_per_100g=1.19)
    vr = validate(r, 'Chicken', 'meat')
    assert vr.verdict == 'PASS'

def test_reject_zero_overlap():
    r = _r(ingredient_name='Dried crayfish',
            scraped_title='Riz Basmati Extra Long CARREFOUR',
            price_per_100g=2.5, package_unit='g')
    vr = validate(r, 'Dried crayfish', 'fish')
    assert vr.verdict == 'REJECT'

# Check 3 — price range
def test_reject_extreme_high_price():
    # 150 > spice max (20) × 5 = 100 → REJECT per spec
    r = _r(ingredient_name='Suya spice powder',
            scraped_title='Suya Spice Mix', price_per_100g=150.0)
    vr = validate(r, 'Suya spice powder', 'spice')
    assert vr.verdict == 'REJECT'

def test_warn_high_but_not_extreme_price():
    # 67.5 is above spice max (20) but below the ×5 reject cutoff → WARN
    r = _r(ingredient_name='Suya spice powder',
            scraped_title='Suya Spice Mix', price_per_100g=67.5)
    vr = validate(r, 'Suya spice powder', 'spice')
    assert vr.verdict == 'WARN'

def test_warn_slightly_outside_range():
    # Ginger at 0.45 €/100g is below spice min of 0.50 but within ×5 buffer
    r = _r(ingredient_name='Ginger', scraped_title='Gingembre frais', price_per_100g=0.45)
    vr = validate(r, 'Ginger', 'spice')
    assert vr.verdict == 'WARN'

def test_pass_in_range():
    r = _r(ingredient_name='Rice', scraped_title='Riz Basmati', price_per_100g=0.255)
    vr = validate(r, 'Rice', 'grain')
    assert vr.verdict == 'PASS'

# Check 4 — unit sanity
def test_auto_correct_solid_with_ml():
    r = _r(ingredient_name='Lamb', scraped_title="Gigot d'agneau",
            price_per_100g=3.625, package_unit='ml')
    vr = validate(r, 'Lamb', 'meat')
    assert vr.corrected_unit == 'g'
    assert vr.verdict == 'WARN'

def test_no_correction_for_liquid():
    r = _r(ingredient_name='Coconut milk', scraped_title='Lait de Coco KARA',
            price_per_100g=0.625, package_unit='ml')
    vr = validate(r, 'Coconut milk', 'dairy')
    assert vr.corrected_unit is None

def test_warn_anomalous_package_size():
    # 133g is not in the allowed set {1,6,50,100,250,500,1000} -> WARN, raw size preserved
    r = _r(ingredient_name='Chicken', scraped_title='Filets de Poulet',
           price_per_100g=1.19, package_size=133.0, package_unit='g')
    vr = validate(r, 'Chicken', 'meat')
    assert vr.verdict == 'WARN'

def test_pass_real_food_not_falsely_blacklisted():
    # 'Porc' is pork in French, which is a legitimate food, not blacklisted
    r = _r(ingredient_name='Pork', scraped_title='Filet De Porc Frais',
           price_per_100g=1.42, package_unit='g')
    vr = validate(r, 'Pork', 'meat')
    assert vr.verdict in ('PASS', 'WARN')  # must not be REJECT
