import re


class Formatter(object):
    def __init__(self, str_len, input_file_name='data/input', output_file_name='data/output'):
        self.str_len = str_len
        self.input_file_name = input_file_name
        self.output_file_name = output_file_name

    def _white_space_extend(self, out_string_words):
        if len(out_string_words) == 1:
            word = out_string_words[0]
            out_string = ' ' * (self.str_len-len(word)) + word
            return out_string
        white_space_expected = self.str_len - len(''.join(out_string_words))
        white_space_for_word = divmod(white_space_expected, (len(out_string_words)-1))
        for i in range(len(out_string_words)-1):
            out_string_words[i] += (' '*white_space_for_word[0])
        for i in range(white_space_for_word[1]):
            out_string_words[i] += ' '
        out_string = ''.join(out_string_words)
        return out_string

    @staticmethod
    def _count_expected_space(out_string_words, exp_word):
        expected_string_length = 0
        for word in out_string_words:
            expected_string_length += len(word)
        expected_string_length += len(exp_word)
        expected_string_length += len(out_string_words)
        return expected_string_length

    def format_text(self):
        is_open = self._open_files()
        if not is_open:
            return
        raw_line = self.in_file.read()
        raw_line = re.sub('\s+', ' ', raw_line)
        words = raw_line.split()
        out_string_words = []
        for word in words:
            word_len = len(word)
            if word_len > self.str_len:
                # уточнить что делать когда есть слова больше чем указанный размер строки.
                print('Слово {} длиннее чем указанный размер строки'.format(word))
                self.out_file.truncate(0)
                return
            if out_string_words:
                expected_string_length = self._count_expected_space(out_string_words, word)
                if expected_string_length > self.str_len:
                    out_string = self._white_space_extend(out_string_words)
                    out_string += '\n'
                    self.out_file.write(out_string)
                    out_string_words = [word]
                else:
                    out_string_words.append(word)
            else:
                out_string_words = [word]
        if len(out_string_words) > 1:
            out_string = self._white_space_extend(out_string_words)
            self.out_file.write(out_string)
        elif len(out_string_words) == 1:
            out_string = out_string_words[0]
            self.out_file.write(out_string)
        self.out_file.flush()
        self._close_files()

    def _close_files(self):
        self.in_file.close()
        self.out_file.close()

    def _open_files(self):
        try:
            self.in_file = open(self.input_file_name, 'r')
        except FileNotFoundError:
            print('Файл "{}" не найден'.format(self.input_file_name))
            return False
        else:
            self.out_file = open(self.output_file_name, 'w')
            return True


if __name__ == '__main__':
    # s_len = 24
    s_len = int(input('Введите размер строки: '))
    formatter = Formatter(s_len)
    formatter.format_text()
