---
tags:
  - source
  - matlab
  - pipeline
  - refactoring
---

# Source: pipeline.m

[Открыть локальный файл](file:///Users/mihailkoseev/Desktop/Projects/hackrf-matlab-spectrum/matlab/pipeline.m)

Путь в проекте:

```text
matlab/pipeline.m
```

## Роль

Текущая входная точка программы во время архитектурного рефакторинга.

## Текущее состояние

Pipeline уже создаёт источник данных через `Configurator` и получает очередные IQ и metadata через единый контракт.

```matlab
configurator = Configurator(cfg);
data_source = configurator.getDataSource();

while true
    [iq_complex, metadata] = data_source.nextData();
end
```

## Следующий этап

Подключить отдельный математический блок и блок вывода.

## Связанные заметки

- [[20 - Старый и новый pipeline]]
- [[13 - Следующие шаги]]
- [[21 - Исходники проекта]]
