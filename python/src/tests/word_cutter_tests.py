import unittest
from text_formatter import Formatter


class CutTestOutput(unittest.TestCase):
    def test_ok_cut_non_round_word(self):
        word = 'машиностроительный'
        expected_array = ['маши', 'ност', 'роит', 'ельн', 'ый']
        str_len = 4
        formatter = Formatter(str_len)
        sliced_word = formatter._word_cutter(word)
        self.assertEqual(len(expected_array), len(sliced_word))
        self.assertListEqual(sliced_word, expected_array)

    def test_ok_cut_round_word(self):
        word = 'список'
        expected_array = ['спи', 'сок']
        str_len = 3
        formatter = Formatter(str_len)
        sliced_word= formatter._word_cutter(word)
        self.assertEqual(len(expected_array), len(sliced_word))
        self.assertListEqual(sliced_word, expected_array)
