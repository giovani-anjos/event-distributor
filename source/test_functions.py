from unittest import TestCase
from . import parser

class TestFunctions(TestCase):
    def test_verify_get_pending_files_returned_type(self):
        expected_result = "<class 'list'>"
        self.assertEqual(str(type(parser.get_pending_files())), expected_result)