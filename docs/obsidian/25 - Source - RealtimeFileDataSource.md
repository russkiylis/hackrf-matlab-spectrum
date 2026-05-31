---
tags:
  - source
  - matlab
  - realtime
---

# Source: RealtimeFileDataSource.m

[Открыть локальный файл](file:///Users/mihailkoseev/Desktop/Projects/hackrf-matlab-spectrum/matlab/RealtimeFileDataSource.m)

Путь в проекте:

```text
matlab/RealtimeFileDataSource.m
```

## Роль

Ждёт запуск GNU Radio, получает свежую полную JSONL-строку и читает соответствующий IQ-файл.

## Ключевой фрагмент

```matlab
waitForFile(fullfile(folder_path, "metadata.jsonl"), 30);
obj@FileDataSource(folder_path);
```

```matlab
fseek(obj.metadata_fid, 0, "eof");
```

## Открытый вопрос

Массовая очистка `*.cf32` пока требует исправления. Подробнее: [[10 - Жизненный цикл файлов]].

## Связанные заметки

- [[08 - RealtimeFileDataSource]]
- [[10 - Жизненный цикл файлов]]
- [[18 - Сценарии использования]]
- [[21 - Исходники проекта]]

