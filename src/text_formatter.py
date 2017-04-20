import re


class Formatter(object):
    def __init__(self, str_len, input_file_name='data/input', output_file_name='data/output'):
        self.str_len = str_len
        self.input_file_name = input_file_name
        self.output_file_name = output_file_name

    def _white_space_extend(self, out_string):
        white_space_count = 1
        # если строка состоит из одного слова то с какой стороны заполнять пробелами?
        while len(out_string) < self.str_len:
            white_space_pattern = '\S+ {{{}}}(?=[\S])'.format(white_space_count)
            search_result = re.search(white_space_pattern, out_string)
            if search_result:
                fragment_result = search_result.group(0)
                out_string = out_string.replace(fragment_result, (fragment_result + ' '))
            else:
                white_space_count += 1
        return out_string

    def format_text(self):
        is_open = self._open_files()
        if not is_open:
            return
        raw_line = self.in_file.read()
        raw_line = re.sub('\s+', ' ', raw_line)
        words = raw_line.split()
        out_string = ''
        for word in words:
            word_len = len(word)
            if word_len > self.str_len:
                # уточнить что делать когда есть слова больше чем указанный размер строки.
                print('Слово {} длиннее чем указанный размер строки'.format(word))
                self.out_file.truncate(0)
                break
            if out_string:
                if len(out_string + ' ' + word) > self.str_len:
                    out_string = self._white_space_extend(out_string)
                    out_string += '\n'
                    self.out_file.write(out_string)
                    out_string = ''
                else:
                    out_string = out_string + ' ' + word
            else:
                out_string = word
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
    s_len = 15
    # s_len = int(input('Введите размер строки: '))
    formatter = Formatter(s_len)
    formatter.format_text()
