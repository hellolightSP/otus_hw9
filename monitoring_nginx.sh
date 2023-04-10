#!/bin/bash

# Блокировка запуска нескольких копий
LOCK=/tmp/monitoring.lock
if [ -f $LOCK ];then 
	echo "Script is already running"
	exit 6
fi
touch $LOCK
trap 'rm -f "$LOCK"; exit $' INT TERM EXIT

# Объявляем переменные
m_date=`date '+%d-%m-%Y_%H-%M-%S'`
OUTPUT=output_$m_date.log
touch $OUTPUT
access=access.log
error=error.log
if [ -f output*.log ]; then
	s_date=`date -d '1 hour ago' "+%Y-%m-%d"`
	s_time=`date -d '1 hour ago' "+%H:%M:%S"`
echo "NGINX LOG: $s_date $s_time" >> $OUTPUT
else
	s_date=`ls -alt --full-time output* | head -n 1 | awk '{print $6}'` #s_date="2023-04-10"

	s_time=`ls -alt --full-time output* | head -n 1 | awk '{print $7}' | cut -f1 -d"."` #s_time="11:51:05"
fi

# Замена месяца. Вид 10/Apr/2023
s_acl="`echo $s_date | awk -F "-" '{print $3,$2,$1}' | sed 's/ /-/g' | {
sed -e '
s/-01-/\/Jan\//
s/-02-/\/Feb\//
s/-03-/\/Mar\//
s/-04-/\/Apr\//
s/-05-/\/May\//
s/-06-/\/Jun\//
s/-07-/\/Jul\//
s/-08-/\/Aug\//
s/-09-/\/Sep\//
s/-10-/\/Oct\//
s/-11-/\/Nov\//
s/-12-/\/Dec\//'
}`:$s_time"
echo "ACCESS: $s_acl"

# Список IP адресов
echo "######################## Список IP адресов с наибольшим кол-вом запросов и с указанием кол-ва запросов c момента последнего запуска скрипта ########################" >> $OUTPUT
awk -v p="$s_acl" '{if ($4 >= p) print $1}' $access | sort | uniq -c | sort -rn | head >> $OUTPUT

# Список запрашиваемых URL
echo "######################## Список запрашиваемых URL с наибольшим кол-вом запросов и с указанием кол-ва запросов c момента последнего запуска скрипта ########################" >> $OUTPUT
awk -v p="$s_acl" '{if ($4 >= p) print $7}' $access | sort | uniq -c | sort -nr | head >> $OUTPUT

# Список ошибок
echo "######################## Все ошибки c момента последнего запуска ########################" >> $OUTPUT
s_date=`echo $s_date | sed 's/-/\//g'`

# Список кодов возврата
awk -v p="$s_date" -v l="$s_time" '{if (($1 >= p)&&($2 >= l)) print}' $error >> $OUTPUT
echo "######################## Список всех кодов возврата с указанием их кол-ва с момента последнего запуска ########################" >> $OUTPUT
awk -v p="$s_acl" '{if ($4 >= p) print $9}' $access | sort | uniq -c | sort -rn >> $OUTPUT

# Отправка email
cat $OUTPUT
mail -s "$m_date Лог nginx c сервера $HOSTNAME" hellolight2011@gmail.com < $OUTPUT
rm -f $LOCK
rm -f $OUTPUT

# Снятие блокировки
trap - INT TERM EXIT
