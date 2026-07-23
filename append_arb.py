import os
import re
import json

def extract_and_append():
    with open('docs/superpowers/plans/2026-07-23-beauty-fix-f-beauty-ui.md', 'r', encoding='utf-8') as f:
        content = f.read()

    # Find Step 1 block for app_en.arb
    en_pattern = r'Change the line `"@onboardingValidationAgeMax": \{\}` to end with a comma, then insert the entire block below immediately before the final `\}`:\s*```json\s*(.*?)\s*```'
    en_match = re.search(en_pattern, content, re.DOTALL)
    if not en_match:
        print("Could not find EN block")
        return

    en_block = en_match.group(1)
    # The block contains the first line `"onboardingValidationAgeMax": "Age must be at most 100",` which we might not want to duplicate if we just replace
    
    with open('lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
        en_arb = f.read()
    
    en_arb_new = en_arb.replace('"@onboardingValidationAgeMax": {}', en_block)
    with open('lib/l10n/app_en.arb', 'w', encoding='utf-8') as f:
        f.write(en_arb_new)
        print("Updated app_en.arb")

    # Find Step 2 block for app_fr.arb
    fr_pattern = r'Same mechanic: change the final `"@onboardingValidationAgeMax": \{\}` to end with a comma and insert this block.*?:\s*```json\s*(.*?)\s*```'
    fr_match = re.search(fr_pattern, content, re.DOTALL)
    if not fr_match:
        print("Could not find FR block")
        return

    fr_block = fr_match.group(1)
    with open('lib/l10n/app_fr.arb', 'r', encoding='utf-8') as f:
        fr_arb = f.read()

    fr_arb_new = fr_arb.replace('"@onboardingValidationAgeMax": {}', fr_block)
    with open('lib/l10n/app_fr.arb', 'w', encoding='utf-8') as f:
        f.write(fr_arb_new)
        print("Updated app_fr.arb")

extract_and_append()
