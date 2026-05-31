---
tags:
  - architecture
  - pipeline
  - refactoring
---

# Старый и новый pipeline

## Текущий старый pipeline

Файл [[27 - Source - pipeline|pipeline.m]] пока использует `RealtimeWasserfall` как центральный объект:

```mermaid
flowchart TD
    Pipeline["pipeline.m"] --> WF["RealtimeWasserfall"]
    WF --> Meta["readMetadata()"]
    WF --> IQ["readIQ()"]
    WF --> Draw["drawWasserfall()"]
    Draw --> Math["FFT, power, dB, compression"]
    Draw --> UI["figure, axes, image"]
```

Проблема: один объект знает почти обо всей программе.

## Первый промежуточный pipeline

После подключения новых источников можно получить:

```mermaid
flowchart LR
    Config["Configurator"] --> Source["FileDataSource-наследник"]
    Source --> IQ["IQ + metadata"]
    IQ --> WF["Временно: старый блок обработки и вывода"]
```

Это промежуточный этап. Его цель - убедиться, что получение данных отделено и работает независимо.

## Целевой pipeline

```mermaid
flowchart LR
    Config["Configurator"] --> Source["DataSource"]
    Source --> Chunk["IQ + metadata"]
    Chunk --> Math["MathBlock"]
    Math --> Spectrum["Строки спектра"]
    Spectrum --> Output["WasserfallOutput"]
```

## Предполагаемое разбиение MathBlock

```mermaid
flowchart TD
    Math["MathBlock.process(iq)"] --> Window["WindowProvider"]
    Window --> FFT["FFTCalculator"]
    FFT --> Power["PowerCalculator"]
    Power --> DB["DbConverter"]
    DB --> Compress["SpectrumCompressor"]
```

Не обязательно сразу создавать отдельный класс под каждый прямоугольник. Сначала можно использовать маленькие функции или private-методы.

## Предполагаемое разбиение блока вывода

```mermaid
flowchart TD
    Output["WasserfallOutput.update(rows)"] --> Buffer["RingBuffer"]
    Output --> Renderer["FigureRenderer"]
    Buffer --> Image["CData"]
    Renderer --> Image
```

## Правильное направление зависимостей

```text
верхний уровень выбирает и координирует
нижние уровни выполняют маленькие задачи
данные движутся явно между блоками
```

Математика не должна импортировать файловые детали. Вывод не должен открывать IQ-файлы. Источник не должен рисовать.

## Связанные заметки

- [[01 - Архитектурная цель]]
- [[02 - Пирамидальная декомпозиция]]
- [[03 - Текущая архитектура источников данных]]
- [[12 - Переход к сети]]
- [[13 - Следующие шаги]]
