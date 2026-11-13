#!/usr/bin/env python3
"""Exercise translation completeness, JSON comments and argument compatibility."""
import json
import unittest

from check_xcstrings import unique_object, validate


def entry(value):
    return {'stringUnit': {'state': 'translated', 'value': value}}


class CatalogChecks(unittest.TestCase):
    def setUp(self):
        self.catalog = {'sourceLanguage': 'en', 'strings': {
            'location': {'comment': '第1引数=地域、第2引数=都市。', 'localizations': {
                'ja': entry('%1$@ %2$@'), 'en': entry('%2$@, %1$@'),
            }},
        }}

    def check(self):
        return validate(self.catalog, ['location'], 'ja', ['en', 'ja'])

    def test_reordering_preserves_argument_meaning(self):
        self.assertEqual(self.check(), ([], []))

    def test_one_source_language_can_be_non_catalog_source(self):
        self.assertEqual(self.catalog['sourceLanguage'], 'en')
        self.assertEqual(self.check(), ([], []))

    def test_missing_translation_fails(self):
        del self.catalog['strings']['location']['localizations']['en']
        self.assertTrue(self.check()[0])

    def test_wrong_argument_type_fails(self):
        self.catalog['strings']['location']['localizations']['en'] = entry('%2$lld, %1$@')
        self.assertTrue(self.check()[0])

    def test_missing_argument_fails(self):
        self.catalog['strings']['location']['localizations']['en'] = entry('%1$@')
        self.assertTrue(self.check()[0])

    def test_percent_escape_is_preserved(self):
        self.catalog['strings']['location']['localizations'] = {
            'ja': entry('%lld%%'), 'en': entry('%1$lld%%'),
        }
        self.assertEqual(self.check(), ([], []))
        self.catalog['strings']['location']['localizations']['en'] = entry('%lld')
        self.assertTrue(self.check()[0])

    def test_json_comment_is_string(self):
        self.catalog['strings']['location']['comment'] = {'invalid': 'context'}
        self.assertTrue(self.check()[0])

    def test_misplaced_comment_fails(self):
        self.catalog['strings']['location']['localizations']['en']['stringUnit']['comment'] = 'context'
        self.assertTrue(self.check()[0])

    def test_plural_requires_manual_review_without_mutation(self):
        self.catalog['strings']['location']['localizations']['en'] = {
            'variations': {'plural': {'other': entry('%lld cards')}},
        }
        before = json.dumps(self.catalog)
        errors, manual = self.check()
        self.assertFalse(errors)
        self.assertTrue(manual)
        self.assertEqual(json.dumps(self.catalog), before)

    def test_duplicate_json_keys_fail(self):
        with self.assertRaises(ValueError):
            json.loads('{"comment":"one","comment":"two"}', object_pairs_hook=unique_object)

    def test_dynamic_precision_requires_manual_review(self):
        self.catalog['strings']['location']['localizations'] = {
            'ja': entry('%.*f'), 'en': entry('%.*f'),
        }
        errors, manual = self.check()
        self.assertFalse(errors)
        self.assertTrue(manual)


if __name__ == '__main__':
    unittest.main()
