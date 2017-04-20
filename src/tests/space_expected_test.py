import unittest
from text_formatter import Formatter


class TestSpaceExpected(unittest.TestCase):
    def setUp(self):
        self.formatter = Formatter(30)

    def test_ok_test_cout_exp_space(self):
        out_string_words = ['one', 'two', 'three']
        word = 'four'
        expected_string = 'one two three four'
        expected_string_length = self.formatter._count_expected_space(out_string_words, word)
        self.assertEqual(expected_string_length, len(expected_string))
