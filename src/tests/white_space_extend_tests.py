import unittest
from text_formatter import Formatter


class TestWhiteSpaceExtend(unittest.TestCase):
    def setUp(self):
        self.input_string = 'Требуется: создать отформатированный текстовый файл,'

    def test_ok_no_add_whitespace(self):
        expect_string = 'Требуется: создать отформатированный текстовый файл,'
        str_len = len(self.input_string)
        formatter = Formatter(str_len=str_len)
        out_str = formatter._white_space_extend(self.input_string)
        self.assertEqual(out_str, expect_string)

    def test_ok_add_2_whitespace(self):
        expect_string = 'Требуется:  создать  отформатированный текстовый файл,'
        str_len = len(self.input_string) + 2
        formatter = Formatter(str_len=str_len)
        out_str = formatter._white_space_extend(self.input_string)
        self.assertEqual(out_str, expect_string)

    def test_ok_add_3_whitespace(self):
        expect_string = 'Требуется:  создать  отформатированный  текстовый файл,'
        str_len = len(self.input_string) + 3
        formatter = Formatter(str_len=str_len)
        out_str = formatter._white_space_extend(self.input_string)
        self.assertEqual(out_str, expect_string)

    def test_ok_add_4_whitespace(self):
        expect_string = 'Требуется:  создать  отформатированный  текстовый  файл,'
        str_len = len(self.input_string) + 4
        formatter = Formatter(str_len=str_len)
        out_str = formatter._white_space_extend(self.input_string)
        self.assertEqual(out_str, expect_string)

    def test_ok_add_6_whitespace(self):
        expect_string = 'Требуется:   создать   отформатированный  текстовый  файл,'
        str_len = len(self.input_string) + 6
        formatter = Formatter(str_len=str_len)
        out_str = formatter._white_space_extend(self.input_string)
        self.assertEqual(out_str, expect_string)

    def test_ok_add_7_whitespace(self):
        expect_string = 'Требуется:   создать   отформатированный   текстовый  файл,'
        str_len = len(self.input_string) + 7
        formatter = Formatter(str_len=str_len)
        out_str = formatter._white_space_extend(self.input_string)
        self.assertEqual(out_str, expect_string)

    def test_ok_add_8_whitespace(self):
        expect_string = 'Требуется:   создать   отформатированный   текстовый   файл,'
        str_len = len(self.input_string) + 8
        formatter = Formatter(str_len=str_len)
        out_str = formatter._white_space_extend(self.input_string)
        self.assertEqual(out_str, expect_string)
