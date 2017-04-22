#### Задание 1.
Дано: произвольный текстовый файл и ограничение по ширине страницы (указано кол-во символов).  
Требуется:  создать отформатированный текстовый файл, удовлетворяющий следующим условиям:   
- абзацы текста разделяются одним из символов \n, \r;
- каждая строка кроме последней строки абзаца состоит ровно из заданного количества символов;
- каждая строка абзаца кроме последней заканчивается не пробельным символом;
- ни на одну строку невозможно перенести первое слово следующей строки;
- необходимые для форматирования строки пробелы распределены между словами равномерно.   

Напишите такую программу форматирования теста на python 

#### Задание 2.  
У вас есть учетная система, базирующаяся на любой удобной вам СУБД, хранящая данные о проводимых сделках,  
 поступивших платежах и суммах распределенных оплат:  
- 1. Каждая сделка может быть оплачена произвольным (возможно, нулевым) количеством платежей.  
- 2. Каждый платеж может оплачивать произвольное (возможно, нулевое) количество сделок.  
- 3. Каждая оплата может быть осуществлена на произвольную сумму.  

##### Задания:  
- Предложите решение по хранению данных об оплатах, возможную структуру дополнительных полей/таблиц.  
- Напишите SQL-запрос, который отобразит  всю  информацию по каждому платежу и одно дополнительное   
  поле pmRest - сумму нераспределенного на оплаты остатка по этому платежу.   
  Для каждого имеющегося в таблице payment платежа должна быть выведена  ровно одна  запись.  
- Обоснуйте эффективность именно такого варианта запроса по сравнению с другими возможными  
  (укажите их) с точки зрения его производительности на больших объемах данных  
  (>100000 сделок/ платежей). В обосновании используйте, в том числе, известные особенности поведения  
  внутреннего планировщика запросов выбранной СУБД*.
