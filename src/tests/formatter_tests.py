import unittest
from text_formatter import Formatter


class TestOutput(unittest.TestCase):
    def setUp(self):
        self.input_file = 'data/input'
        self.output_file_name = 'data/output'

    def test_ok_format_to_10_chars_str_len(self):
        formatter = Formatter(str_len=10,
                              input_file_name=self.input_file,
                              output_file_name=self.output_file_name)

        formatter.format_text()
        out_form_file = open(self.output_file_name)
        formatted_text = out_form_file.read()
        expected_text = ''
        self.assertEqual(formatted_text, expected_text)

    def test_format_to_15_chars_str_len(self):
        formatter = Formatter(str_len=15,
                              input_file_name=self.input_file,
                              output_file_name=self.output_file_name)

        formatter.format_text()
        output = formatter.out_file.read()
        expected_text = \
        """
        1      задание.
        Дано:          
        произвольный   
        текстовый  файл 
        и   ограничение 
        по       ширине 
        страницы       
        (указано кол-во
        символов).     
        Требуется:     
        создать
        """