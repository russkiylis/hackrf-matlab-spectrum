---
tags:
  - source
  - matlab
  - recorded
---

# Source: RecordedFileDataSource.m

[Открыть локальный файл](file:///Users/mihailkoseev/Desktop/Projects/hackrf-matlab-spectrum/matlab/RecordedFileDataSource.m)

Путь в проекте:

```text
matlab/RecordedFileDataSource.m
```

## Роль

Последовательно читает сохранённую запись от первой JSONL-строки до EOF.

## Ключевой фрагмент

```matlab
[metadata, eof_flag] = obj.readMetadata();
if eof_flag == true
    iq_complex = -1;
else
    iq_complex = obj.readIQ(metadata);
end
```

## Связанные заметки

- [[07 - RecordedFileDataSource]]
- [[09 - JSONL и файловый курсор]]
- [[18 - Сценарии использования]]
- [[21 - Исходники проекта]]

