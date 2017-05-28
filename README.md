# Проект Box

Device - D - Аппарат  
Cell - C - Ящик (ячейка)  
Server - S - Сервер  

 1. При каждом получении запроса D или S отправляет зеркальный ответ в формате OK: ПОЛУЧЕННАЯ КОМАНДА. 
Если D отправит запрос, S его получит и D отключится не прочитав ответ, то S уже более не сможет его отправить (т.к. отправка происходит в тот же сокет сразу следующей командой после чтения). Дальше может возникнуть непонятная ситуация, то ли D должен еще раз отправить запрос, то ли сервер её получил и обрабатывает. Скорее всего остановимся на первом варианте.
Любой запрос с D должен содержать sender: "идентификатор устройства" по нему S сможет идентифицировать D. Например эй receiver: "x", открой ячейку "y".
 2. Если команда со стороны S будет направлена на действие с какой-то определенной ячейкой, то команда будет дополнительно содержать cell: "идентификатор ячейки".
 3. Кодировка CP1251 всегда.
 4. При включении D всегда должен присылать команду `status`


## Команды

### open
Команда открытия ячейки от S:

    S > {receiver: "id", command: "open", cell: "y"}

### status
Запрос статуса от S:

    S > {receiver: "id", command: "status"}
    D > {"sender": "id", "command": "status", "is_working": "true", "cells": [{"cell": "y", "is_open": true}, {"cell": "z", "is_open": false}]

статус также может прийти в любой момент со стороны D. Ответ в таком случае будет точно таким же как и в случае когда S запросил статус у D.

### flash
Отправка пакетов записи в flash от S:

    S > {"receiver": "id", "command": "flash", "value":"FLASH:xxxxx:yyyyyyyy"}

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
