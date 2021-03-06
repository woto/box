# Проект Box

### Обозначения  
Device - D - Аппарат, Устройство  
Cell - C - Ящик, Ячейка  
Server - S - Сервер  

 1. D и S всегда включает id команды в пакет, а в ответ ожидает ok: "идентификатор", например отправляет `{"sender": "device", "id": "123"}`, а в ответ получает `{"ok": "123"}`. Это означает, что команда получена. Если D или S не получил ответа об успешном принятии пакета, то он должен попытаться сделать ещё несколько раз, если не получится, то считается что что-то сломалось.
 2. Любой запрос с D должен содержать sender: "идентификатор устройства" по нему S сможет идентифицировать D. Например эй receiver: "x", открой ячейку "y".
 3. Если команда со стороны S будет направлена на действие с какой-то определенной ячейкой, то команда будет дополнительно содержать cell: "идентификатор ячейки".
 4. Кодировка CP1251 всегда.
 5. При включении D всегда должен присылать команду `status`
 6. `sender` и `receiver` более не отправляются Устройству. (Убрано с целью экономии ресурсов на стороне Устройства)


## Команды

### open
Команда открытия ячейки от S:

    S > {command: "open", cell: "y"}

### status
Запрос статуса от S:

    S > {command: "status"}
    D > {"sender": "id", "command": "status", "is_working": "true", "cells": [{"cell": "y", "is_open": true}, {"cell": "z", "is_open": false}]

Статус также может прийти в любой момент со стороны D. Сообщение в таком случае будет точно таким же как и в случае когда S запросил статус у D.

### flash
Отправка пакетов записи в flash от S:

    S > {"command": "flash", "value":"FLASH:xxxxx:yyyyyyyy"}

## Server


### Устройство Device:
    Внешний идентификатор - t.string :external_reference
    Широта - t.float :lat
    Долгота - t.float :lng
    Описание расположения - t.text :location
    Работает ли? - t.boolean :is_working

### Ячейка Cell:
    Принадлежность D - t.references :device, foreign_key: true
    Внешний идентификатор - t.string :external_reference
    Работает ли? - t.boolean :is_working
    Заполнена ли? - t.boolean :is_fill
    Открыта ли? - t.boolean :is_open
    Ширина - t.integer :width
    Высота - t.integer :height
    Длина - t.integer :length

Нагрузочное тестирование

```
{"sender":"sender", "id":"id", "receiver":"receiver", "test":"test"}
watch -n 0,1 "echo '{\"sender\":\"no-reply 2\", \"receiver\":\"bbb\", \"id\":\"id-of-command\", \"text\": \"text 2\"}' | nc avtorif.ru 8084"
watch 'ps -eF | grep celluloid'
echo '{"sender": "sender", "receiver": "receiver", "id": "id", "text": "text"}' | iconv -f utf8 -t cpvtorif.ru 8084 -q 5 | iconv -f cp1251 -t utf8
```
